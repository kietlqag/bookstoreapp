const { Router } = require('express');
const serviceController = require('../controllers/service.controller');

const router = Router();

router.get('/', serviceController.listServices);

module.exports = router;
