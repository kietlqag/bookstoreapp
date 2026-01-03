const serviceService = require('../services/service.service');

async function listServices(_req, res, next) {
  try {
    const services = await serviceService.listServices();
    res.json(services);
  } catch (error) {
    next(error);
  }
}

module.exports = { listServices };
