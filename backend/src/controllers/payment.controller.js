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
    next(error);
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

module.exports = {
  listMethods,
  initiatePayment,
  handleMomoWebhook,
  handleVietqrWebhook,
};
