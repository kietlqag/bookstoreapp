const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const {
  listNotifications,
  getNotification,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
} = require('../controllers/notification.controller');

const router = express.Router();

// Tất cả routes đều yêu cầu authentication
router.use(authenticateToken);

// GET /api/notifications - Lấy danh sách thông báo
router.get('/', listNotifications);

// GET /api/notifications/unread-count - Lấy số lượng thông báo chưa đọc
router.get('/unread-count', getUnreadCount);

// GET /api/notifications/:id - Lấy chi tiết thông báo
router.get('/:id', getNotification);

// PUT /api/notifications/:id/read - Đánh dấu đã đọc
router.put('/:id/read', markAsRead);

// PUT /api/notifications/read-all - Đánh dấu tất cả đã đọc
router.put('/read-all', markAllAsRead);

// DELETE /api/notifications/:id - Xóa thông báo
router.delete('/:id', deleteNotification);

module.exports = router;
