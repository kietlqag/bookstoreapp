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

module.exports = router;
