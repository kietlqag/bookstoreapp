const { pool } = require('../config/db');

function mapSupportRequestRow(row) {
  return {
    id: row.id,
    userId: row.userId,
    orderId: row.orderId,
    subject: row.subject,
    message: row.message,
    category: row.category,
    email: row.email,
    phone: row.phone,
    status: row.status,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function mapSupportMessageRow(row) {
  return {
    id: row.id,
    userId: row.userId,
    requestId: row.requestId,
    message: row.message,
    isFromUser: row.isFromUser,
    isRead: row.isRead ?? false,
    createdAt: row.createdAt,
  };
}

async function createSupportRequest({
  userId,
  orderId = null,
  subject,
  message,
  category = null,
  email = null,
  phone = null,
}) {
  const result = await pool.query(
    'INSERT INTO "SupportRequest" ("userId", "orderId", subject, message, category, email, phone) '
      + 'VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
    [userId, orderId, subject, message, category, email, phone],
  );
  return { id: result.rows[0].id };
}

async function createSupportMessage({
  userId,
  message,
  requestId = null,
  isFromUser = true,
}) {
  const result = await pool.query(
    'INSERT INTO "SupportMessage" ("userId", message, "requestId", "isFromUser", "isRead") '
      + 'VALUES ($1, $2, $3, $4, $5) RETURNING id, "userId", "requestId", message, "isFromUser", "isRead", "createdAt"',
    [userId, message, requestId, isFromUser, false], // New messages are unread by default
  );
  return mapSupportMessageRow(result.rows[0]);
}

async function findMessagesByUserId(userId, requestId = null) {
  let query = 'SELECT id, "userId", "requestId", message, "isFromUser", "isRead", "createdAt" '
    + 'FROM "SupportMessage" '
    + 'WHERE "userId" = $1';
  const params = [userId];

  if (requestId != null) {
    query += ' AND "requestId" = $2';
    params.push(requestId);
  }

  query += ' ORDER BY "createdAt" ASC';

  const result = await pool.query(query, params);
  return result.rows.map(mapSupportMessageRow);
}

// Get new messages after a specific timestamp (for polling)
async function findNewMessagesAfter(afterTimestamp = null, afterId = null) {
  let query = 'SELECT id, "userId", "requestId", message, "isFromUser", "isRead", "createdAt" '
    + 'FROM "SupportMessage" '
    + 'WHERE "isFromUser" = true'; // Chỉ lấy tin nhắn từ khách hàng
  const params = [];

  if (afterId) {
    query += ' AND id > $1';
    params.push(afterId);
  } else if (afterTimestamp) {
    query += ' AND "createdAt" > $1';
    params.push(afterTimestamp);
  }

  query += ' ORDER BY "createdAt" ASC';

  const result = await pool.query(query, params);
  return result.rows.map(mapSupportMessageRow);
}

// Get messages for a specific user (for staff to view chat history)
async function findMessagesByUserIdForStaff(userId) {
  const query = 'SELECT id, "userId", "requestId", message, "isFromUser", "isRead", "createdAt" '
    + 'FROM "SupportMessage" '
    + 'WHERE "userId" = $1 '
    + 'ORDER BY "createdAt" ASC';

  const result = await pool.query(query, [userId]);
  return result.rows.map(mapSupportMessageRow);
}

// Mark messages as read
async function markMessagesAsRead(userId, messageIds = null) {
  let query = 'UPDATE "SupportMessage" SET "isRead" = true WHERE "userId" = $1';
  const params = [userId];

  if (messageIds && messageIds.length > 0) {
    query += ` AND id = ANY($2::int[])`;
    params.push(messageIds);
  } else {
    // Mark all unread messages from staff (isFromUser = false) as read
    query += ' AND "isFromUser" = false AND "isRead" = false';
  }

  query += ' RETURNING id';

  const result = await pool.query(query, params);
  return result.rows.map((row) => row.id);
}

// Get unread message count for a user
async function getUnreadMessageCount(userId) {
  const result = await pool.query(
    'SELECT COUNT(*) FROM "SupportMessage" WHERE "userId" = $1 AND "isFromUser" = false AND "isRead" = false',
    [userId],
  );
  return parseInt(result.rows[0].count, 10);
}

async function findRequestsByUserId(userId) {
  const result = await pool.query(
    'SELECT id, "userId", "orderId", subject, message, category, email, phone, status, "createdAt", "updatedAt" '
      + 'FROM "SupportRequest" '
      + 'WHERE "userId" = $1 '
      + 'ORDER BY "createdAt" DESC',
    [userId],
  );
  return result.rows.map(mapSupportRequestRow);
}

async function findRequestById(requestId, userId) {
  const result = await pool.query(
    'SELECT id, "userId", "orderId", subject, message, category, email, phone, status, "createdAt", "updatedAt" '
      + 'FROM "SupportRequest" '
      + 'WHERE id = $1 AND "userId" = $2',
    [requestId, userId],
  );
  if (result.rowCount === 0) {
    return null;
  }
  return mapSupportRequestRow(result.rows[0]);
}

async function findOrderSummary(orderId, userId) {
  const orderResult = await pool.query(
    'SELECT id, "userId" FROM "Order" WHERE id = $1',
    [orderId],
  );
  if (orderResult.rowCount === 0) {
    return null;
  }
  const order = orderResult.rows[0];
  if (order.userId !== userId) {
    return null;
  }

  const itemsResult = await pool.query(
    'SELECT oi."bookId", oi.quantity, b.title AS "bookTitle", '
      + 'b."imageUrl" AS "bookImageUrl", b.author AS "bookAuthor" '
      + 'FROM "OrderItem" oi '
      + 'LEFT JOIN "Book" b ON b.id = oi."bookId" '
      + 'WHERE oi."orderId" = $1 '
      + 'ORDER BY oi.id LIMIT 3',
    [orderId],
  );

  return {
    id: order.id,
    items: itemsResult.rows.map((row) => ({
      bookId: row.bookId,
      bookTitle: row.bookTitle || '',
      bookImageUrl: row.bookImageUrl || '',
      bookAuthor: row.bookAuthor || '',
      quantity: row.quantity || 0,
    })),
  };
}

// Get list of users who have sent support messages (for staff panel)
async function findUsersWithMessages() {
  const result = await pool.query(
    `SELECT DISTINCT 
      u.id AS "userId",
      u."fullName",
      u.email,
      u."phoneNumber",
      u.avatar,
      COUNT(sm.id) AS "messageCount",
      MAX(sm."createdAt") AS "lastMessageAt"
    FROM "SupportMessage" sm
    INNER JOIN "User" u ON u.id = sm."userId"
    WHERE sm."isFromUser" = true
    GROUP BY u.id, u."fullName", u.email, u."phoneNumber", u.avatar
    ORDER BY MAX(sm."createdAt") DESC`,
  );
  
  return result.rows.map((row) => ({
    userId: row.userId,
    fullName: row.fullName,
    email: row.email,
    phoneNumber: row.phoneNumber,
    avatar: row.avatar,
    messageCount: parseInt(row.messageCount, 10),
    lastMessageAt: row.lastMessageAt,
  }));
}

module.exports = {
  createSupportRequest,
  createSupportMessage,
  findMessagesByUserId,
  findMessagesByUserIdForStaff,
  findNewMessagesAfter,
  findRequestsByUserId,
  findRequestById,
  findOrderSummary,
  findUsersWithMessages,
  markMessagesAsRead,
  getUnreadMessageCount,
};
