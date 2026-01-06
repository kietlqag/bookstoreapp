const { Router } = require('express');
const paymentController = require('../controllers/payment.controller');

const router = Router();

router.get('/methods', paymentController.listMethods);
router.post('/initiate', paymentController.initiatePayment);
router.get('/transactions/:txnRef', paymentController.getTransaction);
router.post('/webhook/momo', paymentController.handleMomoWebhook);
router.post('/webhook/vietqr', paymentController.handleVietqrWebhook);

module.exports = router;
