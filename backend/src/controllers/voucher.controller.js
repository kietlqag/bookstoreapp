const voucherService = require('../services/voucher.service');

async function listVouchers(req, res, next) {
  try {
    const type = typeof req.query.type === 'string' ? req.query.type : null;
    const activeOnly =
      req.query.activeOnly === undefined
        ? true
        : req.query.activeOnly === 'true';
    const vouchers = await voucherService.listVouchers({ type, activeOnly });
    res.json(vouchers);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listVouchers,
};
