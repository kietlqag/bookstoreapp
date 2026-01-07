const notificationRepository = require('../repositories/notification.repository');

function listNotifications(userId, { includeRead = true, limit = null } = {}) {
  return notificationRepository.findAllByUserId(userId, { includeRead, limit });
}

function getNotification(id, userId) {
  return notificationRepository.findById(id, userId);
}

function createNotification({
  userId,
  type,
  title,
  message,
  relatedId = null,
}) {
  return notificationRepository.createNotification({
    userId,
    type,
    title,
    message,
    relatedId,
  });
}

function markAsRead(id, userId) {
  return notificationRepository.markAsRead(id, userId);
}

function markAllAsRead(userId) {
  return notificationRepository.markAllAsRead(userId);
}

function deleteNotification(id, userId) {
  return notificationRepository.deleteNotification(id, userId);
}

function getUnreadCount(userId) {
  return notificationRepository.getUnreadCount(userId);
}

module.exports = {
  listNotifications,
  getNotification,
  createNotification,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
};
