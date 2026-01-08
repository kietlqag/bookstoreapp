const supportRepository = require('../repositories/support.repository');

async function createSupportRequest(payload) {
  // Nếu có orderId, đảm bảo order thuộc về user
  if (payload.orderId != null) {
    // Có thể thêm validation ở đây nếu cần
  }
  return supportRepository.createSupportRequest(payload);
}

function createSupportMessage(payload) {
  return supportRepository.createSupportMessage(payload);
}

async function sendMessage(payload) {
  const message = await supportRepository.createSupportMessage(payload);
  // Trả về danh sách tin nhắn sau khi gửi
  const messages = await supportRepository.findMessagesByUserId(
    payload.userId,
    payload.requestId,
  );
  return messages;
}

function listMessages(userId, requestId = null) {
  return supportRepository.findMessagesByUserId(userId, requestId);
}

function listRequests(userId) {
  return supportRepository.findRequestsByUserId(userId);
}

async function getRequestDetail(requestId, userId) {
  const request = await supportRepository.findRequestById(requestId, userId);
  if (!request) {
    throw new Error('Support request not found.');
  }
  const messages = await supportRepository.findMessagesByUserId(userId, requestId);
  
  let orderSummary = null;
  if (request.orderId) {
    orderSummary = await supportRepository.findOrderSummary(request.orderId, userId);
  }

  return {
    ...request,
    messages,
    orderSummary,
  };
}

function getUsersWithMessages() {
  return supportRepository.findUsersWithMessages();
}

function getNewMessages({ afterTimestamp = null, afterId = null } = {}) {
  return supportRepository.findNewMessagesAfter(afterTimestamp, afterId);
}

function getMessagesForStaff(userId) {
  return supportRepository.findMessagesByUserIdForStaff(userId);
}

function markMessagesAsRead(userId, messageIds = null) {
  return supportRepository.markMessagesAsRead(userId, messageIds);
}

function getUnreadMessageCount(userId) {
  return supportRepository.getUnreadMessageCount(userId);
}

module.exports = {
  createSupportRequest,
  createSupportMessage,
  sendMessage,
  listMessages,
  listRequests,
  getRequestDetail,
  getUsersWithMessages,
  getNewMessages,
  getMessagesForStaff,
  markMessagesAsRead,
  getUnreadMessageCount,
};
