const crypto = require('crypto');
const https = require('https');
const paymentMethodRepository = require('../repositories/payment_method.repository');
const paymentTransactionRepository = require('../repositories/payment_transaction.repository');
const orderService = require('./order.service');

function postJson(url, payload) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(payload);
    const parsed = new URL(url);
    const options = {
      hostname: parsed.hostname,
      path: `${parsed.pathname}${parsed.search}`,
      method: 'POST',
      port: parsed.port || 443,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
      timeout: 15000,
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const parsedBody = JSON.parse(body || '{}');
          resolve({ status: res.statusCode, data: parsedBody });
        } catch (error) {
          console.error('MoMo response parse error:', error);
          reject(error);
        }
      });
    });

    req.on('timeout', () => {
      req.destroy(new Error('Request timeout'));
    });
    req.on('error', (error) => {
      console.error('MoMo request error:', error);
      reject(error);
    });
    req.write(data);
    req.end();
  });
}

async function listPaymentMethods() {
  return paymentMethodRepository.findAll({ activeOnly: true });
}

async function initiatePayment({
  amount,
  methodCode,
  orderId,
  orderPayload,
  returnUrl,
}) {
  const method = await paymentMethodRepository.findByCode(methodCode);
  if (!method || !method.isActive) {
    throw new Error('Payment method is not available.');
  }
  if (!amount || amount <= 0) {
    throw new Error('Amount must be greater than zero.');
  }

  const txnRef = `${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const baseTransaction = await paymentTransactionRepository.createTransaction({
    orderId,
    methodCode: method.code,
    provider: method.provider,
    amount,
    currency: 'VND',
    status: 'pending',
    txnRef,
    orderPayload: orderPayload || null,
  });


  if (method.provider === 'momo') {
    console.log('MoMo initiate start');
    const partnerCode = (process.env.MOMO_PARTNER_CODE || '').trim();
    const accessKey = (process.env.MOMO_ACCESS_KEY || '').trim();
    const secretKey = (process.env.MOMO_SECRET_KEY || '').trim();
    const momoEndpoint = (process.env.MOMO_ENDPOINT || '').trim()
      || 'https://test-payment.momo.vn/v2/gateway/api/create';
    const momoReturnUrl =
      (returnUrl || process.env.MOMO_RETURN_URL || '').trim();
    const momoNotifyUrl = (process.env.MOMO_NOTIFY_URL || '').trim();
    const momoRequestType = process.env.MOMO_REQUEST_TYPE || 'captureWallet';
    const momoExtraData = process.env.MOMO_EXTRA_DATA || '';
    const momoLang = process.env.MOMO_LANG || 'en';

    if (!partnerCode || !accessKey || !secretKey || !momoReturnUrl || !momoNotifyUrl) {
      throw new Error('MoMo config is missing.');
    }

    const requestId = txnRef;
    const orderIdValue = txnRef;
    const amountValue = Math.round(amount).toString();
    const rawSignature =
      `accessKey=${accessKey}&amount=${amountValue}&extraData=${momoExtraData}&ipnUrl=${momoNotifyUrl}`
      + `&orderId=${orderIdValue}&orderInfo=Thanh toan don hang ${txnRef}`
      + `&partnerCode=${partnerCode}&redirectUrl=${momoReturnUrl}`
      + `&requestId=${requestId}&requestType=${momoRequestType}`;
    const signature = crypto
      .createHmac('sha256', secretKey)
      .update(rawSignature)
      .digest('hex');

    const body = {
      partnerCode,
      accessKey,
      requestId,
      amount: amountValue,
      orderId: orderIdValue,
      orderInfo: `Thanh toan don hang ${txnRef}`,
      redirectUrl: momoReturnUrl,
      ipnUrl: momoNotifyUrl,
      requestType: momoRequestType,
      extraData: momoExtraData,
      signature,
      lang: momoLang,
    };

    console.log('MoMo request payload:', {
      partnerCode,
      requestId,
      amount: amountValue,
      orderId: orderIdValue,
      redirectUrl: momoReturnUrl,
      ipnUrl: momoNotifyUrl,
      requestType: momoRequestType,
    });
    const response = await postJson(momoEndpoint, body);
    console.log('MoMo response:', response);
    if (!response.data || !response.data.payUrl) {
      const resultCode = response.data?.resultCode ?? 'unknown';
      const message = response.data?.message ?? 'no message';
      throw new Error(
        `MoMo create payment failed. resultCode=${resultCode} message=${message}`,
      );
    }
    const transaction = await paymentTransactionRepository.updateTransaction(
      baseTransaction.id,
      {
        paymentUrl: response.data.payUrl,
        providerTxnId: response.data.transId?.toString(),
      },
    );
    return {
      transaction,
      txnRef: baseTransaction.txnRef,
      paymentUrl: response.data.payUrl,
      deeplink: response.data.deeplink,
      qrCodeUrl: response.data.qrCodeUrl,
      deeplinkMiniApp: response.data.deeplinkMiniApp,
    };
  }

  if (method.provider === 'vietqr') {
    const bankBin = process.env.VIETQR_BANK_BIN;
    const accountNumber = process.env.VIETQR_ACCOUNT_NUMBER;
    const accountName = process.env.VIETQR_ACCOUNT_NAME;
    if (!bankBin || !accountNumber || !accountName) {
      throw new Error('VietQR config is missing.');
    }
    const amountValue = Math.round(amount);
    const addInfo = encodeURIComponent(`BOOKSTORE ${txnRef}`);
    const nameParam = encodeURIComponent(accountName);
    const qrImageUrl =
      `https://img.vietqr.io/image/${bankBin}-${accountNumber}-print.png`
      + `?amount=${amountValue}&addInfo=${addInfo}&accountName=${nameParam}`;

    const transaction = await paymentTransactionRepository.updateTransaction(
      baseTransaction.id,
      { qrContent: qrImageUrl },
    );
    return {
      transaction,
      qrImageUrl,
      qrContent: qrImageUrl,
    };
  }

  if (method.provider === 'cod') {
    const transaction = await paymentTransactionRepository.updateTransaction(
      baseTransaction.id,
      {
        status: 'succeeded',
        rawPayload: { method: 'cod' },
      },
    );
    let orderId = null;
    if (orderPayload) {
      const order = await orderService.createOrder({
        userId: Number(orderPayload.userId),
        serviceId: orderPayload.serviceId ? Number(orderPayload.serviceId) : null,
        paymentId: transaction.id,
        recipientName: orderPayload.recipientName || null,
        shippingAddressNew: orderPayload.shippingAddressNew || null,
        shippingAddressOld: orderPayload.shippingAddressOld || null,
        phoneNumber: orderPayload.phoneNumber || null,
        note: orderPayload.note || null,
        status: 'pending_confirmation',
        subtotal: orderPayload.subtotal,
        shippingFee: orderPayload.shippingFee,
        productDiscount: orderPayload.productDiscount,
        shippingDiscount: orderPayload.shippingDiscount,
        totalPrice: orderPayload.totalPrice,
        cartItemIds: orderPayload.cartItemIds || [],
        shippingVoucherId: orderPayload.shippingVoucherId || null,
        productVoucherId: orderPayload.productVoucherId || null,
        items: Array.isArray(orderPayload.items)
          ? orderPayload.items.map((item) => ({
              bookId: Number(item.bookId) || 0,
              quantity: Number(item.quantity) || 0,
              price: Number(item.price) || 0,
            }))
          : [],
      });
      orderId = order.id;
      await paymentTransactionRepository.updateTransaction(transaction.id, {
        orderId: order.id,
      });
    }
    return {
      transaction,
      orderId,
    };
  }

  throw new Error('Unsupported payment provider.');
}


async function handleMomoWebhook(payload) {
  const secretKey = process.env.MOMO_SECRET_KEY;
  if (!secretKey) {
    throw new Error('MoMo config is missing.');
  }
  const pick = (value) => (value === undefined || value === null ? '' : value);
  const rawSignature =
    `accessKey=${pick(payload.accessKey)}&amount=${pick(payload.amount)}&extraData=${pick(payload.extraData)}`
    + `&message=${pick(payload.message)}&orderId=${pick(payload.orderId)}&orderInfo=${pick(payload.orderInfo)}`
    + `&orderType=${pick(payload.orderType)}&partnerCode=${pick(payload.partnerCode)}`
    + `&payType=${pick(payload.payType)}&requestId=${pick(payload.requestId)}`
    + `&responseTime=${pick(payload.responseTime)}&resultCode=${pick(payload.resultCode)}`
    + `&transId=${pick(payload.transId)}`;
  const signed = crypto
    .createHmac('sha256', secretKey)
    .update(rawSignature)
    .digest('hex');
  if (payload.signature !== signed) {
    console.warn('MoMo webhook signature mismatch:', {
      expected: signed,
      received: payload.signature,
      rawSignature,
    });
    return { code: 97, message: 'Invalid signature' };
  }
  const success = Number(payload.resultCode) === 0;
  const transaction = await paymentTransactionRepository.updateByTxnRef(
    payload.orderId,
    {
    status: success ? 'succeeded' : 'failed',
    providerTxnId: payload.transId?.toString(),
    rawPayload: payload,
    },
  );
  await handlePaidOrder(transaction);
  return { code: 0, message: 'OK' };
}

async function handleVietqrWebhook(payload) {
  const txnRef = payload.txnRef || payload.orderId || payload.reference;
  if (!txnRef) {
    throw new Error('Missing transaction reference.');
  }
  const status = payload.status || payload.state;
  const success = status === 'success' || status === 'paid';
  const transaction = await paymentTransactionRepository.updateByTxnRef(txnRef, {
    status: success ? 'succeeded' : 'failed',
    providerTxnId: payload.transactionId?.toString(),
    rawPayload: payload,
  });
  await handlePaidOrder(transaction);
  return { code: 0, message: 'OK' };
}

async function handlePaidOrder(transaction) {
  if (!transaction) return;
  if (transaction.status !== 'succeeded') return;
  if (transaction.orderId) return;
  if (!transaction.orderPayload) return;

  const payload = transaction.orderPayload;
  const order = await orderService.createOrder({
    userId: Number(payload.userId),
    serviceId: payload.serviceId ? Number(payload.serviceId) : null,
    paymentId: transaction.id,
    recipientName: payload.recipientName || null,
    shippingAddressNew: payload.shippingAddressNew || null,
    shippingAddressOld: payload.shippingAddressOld || null,
    phoneNumber: payload.phoneNumber || null,
    note: payload.note || null,
    status: 'waiting_pickup',
    subtotal: payload.subtotal,
    shippingFee: payload.shippingFee,
    productDiscount: payload.productDiscount,
    shippingDiscount: payload.shippingDiscount,
    totalPrice: payload.totalPrice,
    cartItemIds: payload.cartItemIds || [],
    shippingVoucherId: payload.shippingVoucherId || null,
    productVoucherId: payload.productVoucherId || null,
    items: Array.isArray(payload.items)
      ? payload.items.map((item) => ({
          bookId: Number(item.bookId) || 0,
          quantity: Number(item.quantity) || 0,
          price: Number(item.price) || 0,
        }))
      : [],
  });

  await paymentTransactionRepository.updateTransaction(transaction.id, {
    orderId: order.id,
  });
}

module.exports = {
  listPaymentMethods,
  initiatePayment,
  getTransactionByRef: paymentTransactionRepository.findByTxnRef,
  handleMomoWebhook,
  handleVietqrWebhook,
};
