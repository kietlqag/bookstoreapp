const serviceRepository = require('../repositories/service.repository');

function listServices() {
  return serviceRepository.listServices();
}

module.exports = { listServices };
