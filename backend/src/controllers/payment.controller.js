const paymentService = require('../services/payment.service');

async function listMethods(_req, res, next) {
  try {
    const methods = await paymentService.listPaymentMethods();
    res.json(methods);
  } catch (error) {
    next(error);
  }
}

async function initiatePayment(req, res, next) {
  try {
    const { amount, methodCode, orderId, returnUrl, orderPayload } =
      req.body || {};
    const parsedAmount = typeof amount === 'number' ? amount : Number(amount) || 0;
    const result = await paymentService.initiatePayment({
      amount: parsedAmount,
      methodCode,
      orderId,
      orderPayload,
      returnUrl,
    });
    res.json(result);
  } catch (error) {
    console.error('Payment initiate error:', error);
    res.status(500).json({
      message: error?.message || 'Payment initiate failed',
    });
  }
}


async function handleMomoWebhook(req, res, next) {
  try {
    const result = await paymentService.handleMomoWebhook(req.body || {});
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function handleVietqrWebhook(req, res, next) {
  try {
    const result = await paymentService.handleVietqrWebhook(req.body || {});
    res.json(result);
  } catch (error) {
    next(error);
  }
}

async function getTransaction(req, res, next) {
  try {
    const txnRef = req.params.txnRef?.toString();
    if (!txnRef) {
      return res.status(400).json({ message: 'Invalid transaction reference.' });
    }
    const transaction = await paymentService.getTransactionByRef(txnRef);
    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found.' });
    }
    return res.json({
      status: transaction.status,
      orderId: transaction.orderId || null,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listMethods,
  initiatePayment,
  handleMomoWebhook,
  handleVietqrWebhook,
  getTransaction,
};
