const notificationService = require('../services/notification.service');

async function listNotifications(req, res, next) {
  try {
    const userId = req.user.id;
    const includeRead = req.query.includeRead !== 'false';
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : null;

    const notifications = await notificationService.listNotifications(userId, {
      includeRead,
      limit,
    });

    res.json(notifications);
  } catch (error) {
    next(error);
  }
}

async function getNotification(req, res, next) {
  try {
    const userId = req.user.id;
    const id = parseInt(req.params.id, 10);

    const notification = await notificationService.getNotification(id, userId);

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found.' });
    }

    res.json(notification);
  } catch (error) {
    next(error);
  }
}

async function markAsRead(req, res, next) {
  try {
    const userId = req.user.id;
    const id = parseInt(req.params.id, 10);

    const notification = await notificationService.markAsRead(id, userId);

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found.' });
    }

    res.json(notification);
  } catch (error) {
    next(error);
  }
}

async function markAllAsRead(req, res, next) {
  try {
    const userId = req.user.id;

    const count = await notificationService.markAllAsRead(userId);

    res.json({ message: 'All notifications marked as read.', count });
  } catch (error) {
    next(error);
  }
}

async function deleteNotification(req, res, next) {
  try {
    const userId = req.user.id;
    const id = parseInt(req.params.id, 10);

    const deleted = await notificationService.deleteNotification(id, userId);

    if (!deleted) {
      return res.status(404).json({ message: 'Notification not found.' });
    }

    res.json({ message: 'Notification deleted.' });
  } catch (error) {
    next(error);
  }
}

async function getUnreadCount(req, res, next) {
  try {
    const userId = req.user.id;

    const count = await notificationService.getUnreadCount(userId);

    res.json({ count });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listNotifications,
  getNotification,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
};
