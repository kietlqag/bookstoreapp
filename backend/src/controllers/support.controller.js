const supportService = require('../services/support.service');

async function createSupportRequest(req, res, next) {
  try {
    const {
      userId,
      orderId,
      subject,
      message,
      category,
      email,
      phone,
    } = req.body || {};

    const parsedUserId = Number(userId);
    const parsedOrderId = orderId ? Number(orderId) : null;

    if (!Number.isInteger(parsedUserId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    if (parsedOrderId !== null && !Number.isInteger(parsedOrderId)) {
      return res.status(400).json({ message: 'Invalid order id.' });
    }

    if (!subject || typeof subject !== 'string' || subject.trim().length === 0) {
      return res.status(400).json({ message: 'Subject is required.' });
    }

    if (!message || typeof message !== 'string' || message.trim().length < 10) {
      return res.status(400).json({ message: 'Message must be at least 10 characters.' });
    }

    const safeSubject = subject.trim();
    const safeMessage = message.trim();
    const safeCategory = category?.toString().trim() || null;
    const safeEmail = email?.toString().trim() || null;
    const safePhone = phone?.toString().trim() || null;

    // Validate email format if provided
    if (safeEmail && !safeEmail.includes('@')) {
      return res.status(400).json({ message: 'Invalid email format.' });
    }

    const result = await supportService.createSupportRequest({
      userId: parsedUserId,
      orderId: parsedOrderId,
      subject: safeSubject,
      message: safeMessage,
      category: safeCategory,
      email: safeEmail,
      phone: safePhone,
    });

    return res.status(201).json({ id: result.id });
  } catch (error) {
    return next(error);
  }
}

async function sendMessage(req, res, next) {
  try {
    const {
      userId,
      message: messageText,
      requestId,
    } = req.body || {};

    const parsedUserId = Number(userId);
    const parsedRequestId = requestId ? Number(requestId) : null;

    if (!Number.isInteger(parsedUserId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    if (!messageText || typeof messageText !== 'string' || messageText.trim().length === 0) {
      return res.status(400).json({ message: 'Message is required.' });
    }

    const safeMessage = messageText.trim();

    const messages = await supportService.sendMessage({
      userId: parsedUserId,
      message: safeMessage,
      requestId: parsedRequestId,
      isFromUser: true,
    });

    return res.json(messages);
  } catch (error) {
    return next(error);
  }
}

async function listMessages(req, res, next) {
  try {
    const userId = Number(req.query.userId);
    const requestId = req.query.requestId ? Number(req.query.requestId) : null;

    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    if (requestId !== null && !Number.isInteger(requestId)) {
      return res.status(400).json({ message: 'Invalid request id.' });
    }

    const messages = await supportService.listMessages(userId, requestId);
    return res.json(messages);
  } catch (error) {
    return next(error);
  }
}

async function listRequests(req, res, next) {
  try {
    const userId = Number(req.query.userId);

    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const requests = await supportService.listRequests(userId);
    return res.json(requests);
  } catch (error) {
    return next(error);
  }
}

async function getRequestDetail(req, res, next) {
  try {
    const requestId = Number(req.params.id);
    const userId = Number(req.query.userId);

    if (!Number.isInteger(requestId)) {
      return res.status(400).json({ message: 'Invalid request id.' });
    }

    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const request = await supportService.getRequestDetail(requestId, userId);
    return res.json(request);
  } catch (error) {
    if (error.message === 'Support request not found.') {
      return res.status(404).json({ message: error.message });
    }
    return next(error);
  }
}

// For staff/admin: Get list of users with messages
async function getUsersList(req, res, next) {
  try {
    // Check if user is staff/admin (nên check trong middleware, tạm thời cho phép)
    const users = await supportService.getUsersWithMessages();
    return res.json(users);
  } catch (error) {
    return next(error);
  }
}

// For staff/admin: Check new messages (polling)
async function checkNewMessages(req, res, next) {
  try {
    const { afterId, afterTimestamp } = req.query;
    
    let afterIdNum = null;
    let afterTimestampDate = null;
    
    if (afterId) {
      afterIdNum = Number(afterId);
      if (!Number.isInteger(afterIdNum)) {
        return res.status(400).json({ message: 'Invalid afterId.' });
      }
    }
    
    if (afterTimestamp) {
      afterTimestampDate = new Date(afterTimestamp);
      if (isNaN(afterTimestampDate.getTime())) {
        return res.status(400).json({ message: 'Invalid afterTimestamp format. Use ISO 8601.' });
      }
    }

    const newMessages = await supportService.getNewMessages({
      afterId: afterIdNum,
      afterTimestamp: afterTimestampDate,
    });

    return res.json({
      hasNew: newMessages.length > 0,
      count: newMessages.length,
      messages: newMessages,
      lastMessageId: newMessages.length > 0 
        ? newMessages[newMessages.length - 1].id 
        : (afterIdNum || null),
    });
  } catch (error) {
    return next(error);
  }
}

// For staff/admin: Get messages for a specific user
async function getMessagesForStaff(req, res, next) {
  try {
    const userId = Number(req.params.userId);

    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const messages = await supportService.getMessagesForStaff(userId);
    return res.json(messages);
  } catch (error) {
    return next(error);
  }
}

// Mark messages as read
async function markMessagesAsRead(req, res, next) {
  try {
    const userId = Number(req.body.userId || req.query.userId);
    const messageIds = req.body.messageIds ? req.body.messageIds.map((id) => Number(id)) : null;

    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    if (messageIds && !Array.isArray(messageIds)) {
      return res.status(400).json({ message: 'Message IDs must be an array.' });
    }

    const readMessageIds = await supportService.markMessagesAsRead(userId, messageIds);
    return res.json({ messageIds: readMessageIds });
  } catch (error) {
    return next(error);
  }
}

// Get unread message count
async function getUnreadMessageCount(req, res, next) {
  try {
    const userId = Number(req.query.userId || req.params.userId);

    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const count = await supportService.getUnreadMessageCount(userId);
    return res.json({ count });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createSupportRequest,
  sendMessage,
  listMessages,
  listRequests,
  getRequestDetail,
  getUsersList,
  checkNewMessages,
  getMessagesForStaff,
  markMessagesAsRead,
  getUnreadMessageCount,
};
