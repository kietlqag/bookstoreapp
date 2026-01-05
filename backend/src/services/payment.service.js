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
          reject(error);
        }
      });
    });

    req.on('error', reject);
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
    const partnerCode = process.env.MOMO_PARTNER_CODE;
    const accessKey = process.env.MOMO_ACCESS_KEY;
    const secretKey = process.env.MOMO_SECRET_KEY;
    const momoEndpoint = process.env.MOMO_ENDPOINT
      || 'https://test-payment.momo.vn/v2/gateway/api/create';
    const momoReturnUrl = returnUrl || process.env.MOMO_RETURN_URL;
    const momoNotifyUrl = process.env.MOMO_NOTIFY_URL;

    if (!partnerCode || !accessKey || !secretKey || !momoReturnUrl || !momoNotifyUrl) {
      throw new Error('MoMo config is missing.');
    }

    const requestId = txnRef;
    const orderIdValue = txnRef;
    const amountValue = Math.round(amount).toString();
    const requestType = 'captureWallet';
    const rawSignature =
      `accessKey=${accessKey}&amount=${amountValue}&extraData=&ipnUrl=${momoNotifyUrl}`
      + `&orderId=${orderIdValue}&orderInfo=Thanh toan don hang ${txnRef}`
      + `&partnerCode=${partnerCode}&redirectUrl=${momoReturnUrl}`
      + `&requestId=${requestId}&requestType=${requestType}`;
    const signature = crypto
      .createHmac('sha256', secretKey)
      .update(rawSignature)
      .digest('hex');

    const body = {
      partnerCode,
      requestId,
      amount: amountValue,
      orderId: orderIdValue,
      orderInfo: `Thanh toan don hang ${txnRef}`,
      redirectUrl: momoReturnUrl,
      ipnUrl: momoNotifyUrl,
      requestType,
      extraData: '',
      signature,
      lang: 'vi',
    };

    const response = await postJson(momoEndpoint, body);
    if (!response.data || !response.data.payUrl) {
      throw new Error('MoMo create payment failed.');
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
      paymentUrl: response.data.payUrl,
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
        shippingAddressNew: orderPayload.shippingAddressNew || null,
        shippingAddressOld: orderPayload.shippingAddressOld || null,
        phoneNumber: orderPayload.phoneNumber || null,
        note: orderPayload.note || null,
        status: 'pending_confirmation',
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
  const rawSignature =
    `accessKey=${payload.accessKey}&amount=${payload.amount}&extraData=${payload.extraData}`
    + `&message=${payload.message}&orderId=${payload.orderId}&orderInfo=${payload.orderInfo}`
    + `&orderType=${payload.orderType}&partnerCode=${payload.partnerCode}`
    + `&payType=${payload.payType}&requestId=${payload.requestId}`
    + `&responseTime=${payload.responseTime}&resultCode=${payload.resultCode}`
    + `&transId=${payload.transId}`;
  const signed = crypto
    .createHmac('sha256', secretKey)
    .update(rawSignature)
    .digest('hex');
  if (payload.signature !== signed) {
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
    shippingAddressNew: payload.shippingAddressNew || null,
    shippingAddressOld: payload.shippingAddressOld || null,
    phoneNumber: payload.phoneNumber || null,
    note: payload.note || null,
    status: 'waiting_pickup',
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
  handleMomoWebhook,
  handleVietqrWebhook,
};
