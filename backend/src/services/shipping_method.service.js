const shippingMethodRepository = require('../repositories/shipping_method.repository');

function listShippingMethods({ activeOnly }) {
  return shippingMethodRepository.findAll({ activeOnly });
}

module.exports = {
  listShippingMethods,
};
