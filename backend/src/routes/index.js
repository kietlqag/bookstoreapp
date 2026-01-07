const { Router } = require('express');

const authRoutes = require('./auth.routes');
const bookRoutes = require('./book.routes');
const categoryRoutes = require('./category.routes');
const userRoutes = require('./user.routes');
const cartRoutes = require('./cart.routes');
const serviceRoutes = require('./service.routes');
const paymentRoutes = require('./payment.routes');
const orderRoutes = require('./order.routes');
const reviewRoutes = require('./review.routes');
const healthRoutes = require('./health.routes');
const favoriteRoutes = require('./favorite.routes');
const addressRoutes = require('./address.routes');
const voucherRoutes = require('./voucher.routes');
const shippingMethodRoutes = require('./shipping_method.routes');
const supportRoutes = require('./support.routes');
const chatRoutes = require('./chat.routes');
const notificationRoutes = require('./notification.routes');

const router = Router();

router.use('/health', healthRoutes);
router.use('/auth', authRoutes);
router.use('/books', bookRoutes);
router.use('/categories', categoryRoutes);
router.use('/users', userRoutes);
router.use('/carts', cartRoutes);
router.use('/services', serviceRoutes);
router.use('/payments', paymentRoutes);
router.use('/orders', orderRoutes);
router.use('/reviews', reviewRoutes);
router.use('/favorites', favoriteRoutes);
router.use('/addresses', addressRoutes);
router.use('/vouchers', voucherRoutes);
router.use('/shipping-methods', shippingMethodRoutes);
router.use('/support', supportRoutes);
router.use('/chat', chatRoutes);
router.use('/notifications', notificationRoutes);

module.exports = router;
