const { Router } = require('express');
const paymentController = require('../controllers/payment.controller');

const router = Router();

router.post('/', paymentController.createPayment);

module.exports = router;
