const paymentRepository = require('../repositories/payment.repository');

function createPayment({ amount, method, paymentStatus }) {
  return paymentRepository.createPayment({ amount, method, paymentStatus });
}

module.exports = { createPayment };
