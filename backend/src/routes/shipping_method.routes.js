const { Router } = require('express');
const shippingMethodController = require('../controllers/shipping_method.controller');

const router = Router();

router.get('/', shippingMethodController.listShippingMethods);

module.exports = router;
