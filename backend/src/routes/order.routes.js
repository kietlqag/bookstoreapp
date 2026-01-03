const { Router } = require('express');
const orderController = require('../controllers/order.controller');

const router = Router();

router.post('/', orderController.createOrder);
router.get('/users/:userId', orderController.listOrders);

module.exports = router;
