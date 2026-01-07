const { Router } = require('express');
const supportController = require('../controllers/support.controller');

const router = Router();

router.post('/requests', supportController.createSupportRequest);
router.get('/requests', supportController.listRequests);
router.get('/requests/:id', supportController.getRequestDetail);
router.post('/messages', supportController.sendMessage);
router.get('/messages', supportController.listMessages);

module.exports = router;
