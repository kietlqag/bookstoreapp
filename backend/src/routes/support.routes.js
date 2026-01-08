const { Router } = require('express');
const supportController = require('../controllers/support.controller');
const { authenticateToken } = require('../middleware/auth');

const router = Router();

router.post('/requests', supportController.createSupportRequest);
router.get('/requests', supportController.listRequests);
router.get('/requests/:id', supportController.getRequestDetail);
router.post('/messages', supportController.sendMessage);
router.get('/messages', supportController.listMessages);
router.put('/messages/read', supportController.markMessagesAsRead);
router.get('/messages/unread-count', supportController.getUnreadMessageCount);

// Staff/Admin routes - require authentication
router.get('/staff/users', authenticateToken, supportController.getUsersList);
router.get('/staff/messages/new', authenticateToken, supportController.checkNewMessages);
router.get('/staff/messages/user/:userId', authenticateToken, supportController.getMessagesForStaff);

module.exports = router;
