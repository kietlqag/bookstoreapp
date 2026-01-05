const { Router } = require('express');
const voucherController = require('../controllers/voucher.controller');

const router = Router();

router.get('/', voucherController.listVouchers);

module.exports = router;
