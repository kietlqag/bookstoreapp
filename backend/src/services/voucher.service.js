const voucherRepository = require('../repositories/voucher.repository');

function listVouchers({ type, activeOnly }) {
  return voucherRepository.findAll({ type, activeOnly });
}

module.exports = {
  listVouchers,
};
