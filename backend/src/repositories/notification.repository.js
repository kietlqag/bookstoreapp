const { pool } = require('../config/db');

function mapNotificationRow(row) {
  return {
    id: row.id,
    userId: row.userId,
    type: row.type,
    title: row.title,
    message: row.message,
    isRead: row.isRead,
    relatedId: row.relatedId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function findAllByUserId(userId, { includeRead = true, limit = null } = {}) {
  let query = 'SELECT * FROM "Notification" WHERE "userId" = $1';
  const params = [userId];

  if (!includeRead) {
    query += ' AND "isRead" = false';
  }

  query += ' ORDER BY "createdAt" DESC';

  if (limit) {
    params.push(limit);
    query += ` LIMIT $${params.length}`;
  }

  const result = await pool.query(query, params);
  return result.rows.map(mapNotificationRow);
}

async function findById(id, userId) {
  const result = await pool.query(
    'SELECT * FROM "Notification" WHERE id = $1 AND "userId" = $2',
    [id, userId],
  );

  if (result.rows.length === 0) {
    return null;
  }

  return mapNotificationRow(result.rows[0]);
}

async function createNotification({
  userId,
  type,
  title,
  message,
  relatedId = null,
}) {
  const result = await pool.query(
    'INSERT INTO "Notification" ("userId", type, title, message, "relatedId") '
      + 'VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [userId, type, title, message, relatedId],
  );

  return mapNotificationRow(result.rows[0]);
}

async function markAsRead(id, userId) {
  const result = await pool.query(
    'UPDATE "Notification" SET "isRead" = true, "updatedAt" = CURRENT_TIMESTAMP '
      + 'WHERE id = $1 AND "userId" = $2 RETURNING *',
    [id, userId],
  );

  if (result.rows.length === 0) {
    return null;
  }

  return mapNotificationRow(result.rows[0]);
}

async function markAllAsRead(userId) {
  const result = await pool.query(
    'UPDATE "Notification" SET "isRead" = true, "updatedAt" = CURRENT_TIMESTAMP '
      + 'WHERE "userId" = $1 AND "isRead" = false',
    [userId],
  );

  return result.rowCount || 0;
}

async function deleteNotification(id, userId) {
  const result = await pool.query(
    'DELETE FROM "Notification" WHERE id = $1 AND "userId" = $2 RETURNING id',
    [id, userId],
  );

  return result.rows.length > 0;
}

async function getUnreadCount(userId) {
  const result = await pool.query(
    'SELECT COUNT(*) as count FROM "Notification" WHERE "userId" = $1 AND "isRead" = false',
    [userId],
  );

  return parseInt(result.rows[0]?.count || 0, 10);
}

module.exports = {
  findAllByUserId,
  findById,
  createNotification,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  getUnreadCount,
};
