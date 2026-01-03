const paymentService = require('../services/payment.service');

async function createPayment(req, res, next) {
  try {
    const { amount, method, paymentStatus } = req.body || {};
    const parsedAmount = typeof amount === 'number' ? amount : Number(amount) || 0;

    const payment = await paymentService.createPayment({
      amount: parsedAmount,
      method: method || null,
      paymentStatus: paymentStatus || null,
    });

    res.json(payment);
  } catch (error) {
    next(error);
  }
}

module.exports = { createPayment };
