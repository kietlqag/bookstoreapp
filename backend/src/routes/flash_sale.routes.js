const { Router } = require('express');
const flashSaleController = require('../controllers/flash_sale.controller');

const router = Router();

router.get('/active', flashSaleController.getActiveFlashSale);

module.exports = router;
