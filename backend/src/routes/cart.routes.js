const { Router } = require('express');
const cartController = require('../controllers/cart.controller');

const router = Router();

router.get('/users/:userId', cartController.listCartItems);
router.post('/', cartController.addToCart);
router.patch('/:cartId', cartController.updateCartItem);
router.delete('/:cartId', cartController.removeCartItem);

module.exports = router;
