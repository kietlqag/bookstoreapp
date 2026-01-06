const { Router } = require('express');
const orderController = require('../controllers/order.controller');

const router = Router();

router.post('/', orderController.createOrder);
router.get('/users/:userId', orderController.listOrders);
router.patch('/:orderId/address', orderController.updateOrderAddress);
router.patch('/:orderId/status', orderController.updateOrderStatus);

module.exports = router;
