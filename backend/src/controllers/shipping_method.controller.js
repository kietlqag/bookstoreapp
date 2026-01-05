const shippingMethodService = require('../services/shipping_method.service');

async function listShippingMethods(req, res, next) {
  try {
    const activeOnly =
      req.query.activeOnly === undefined
        ? true
        : req.query.activeOnly === 'true';
    const methods = await shippingMethodService.listShippingMethods({
      activeOnly,
    });
    res.json(methods);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listShippingMethods,
};
