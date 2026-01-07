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
    'INSERT INTO "SupportMessage" ("userId", message, "requestId", "isFromUser") '
      + 'VALUES ($1, $2, $3, $4) RETURNING id, "userId", "requestId", message, "isFromUser", "createdAt"',
    [userId, message, requestId, isFromUser],
  );
  return mapSupportMessageRow(result.rows[0]);
}

async function findMessagesByUserId(userId, requestId = null) {
  let query = 'SELECT id, "userId", "requestId", message, "isFromUser", "createdAt" '
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

module.exports = {
  createSupportRequest,
  createSupportMessage,
  findMessagesByUserId,
  findRequestsByUserId,
  findRequestById,
  findOrderSummary,
};
