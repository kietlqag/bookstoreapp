const { pool } = require('../config/db');

async function findByEmail(email) {
  const result = await pool.query(
    'SELECT * FROM "User" WHERE email = $1 LIMIT 1',
    [email],
  );
  return result.rows[0] || null;
}

async function findById(id) {
  const result = await pool.query('SELECT * FROM "User" WHERE id = $1', [id]);
  return result.rows[0] || null;
}

async function findByGoogleId(googleId) {
  const result = await pool.query(
    'SELECT * FROM "User" WHERE "googleId" = $1 LIMIT 1',
    [googleId],
  );
  return result.rows[0] || null;
}

async function findByFacebookId(facebookId) {
  const result = await pool.query(
    'SELECT * FROM "User" WHERE "facebookId" = $1 LIMIT 1',
    [facebookId],
  );
  return result.rows[0] || null;
}

async function createUser({
  fullName,
  email,
  passwordHash,
  googleId = null,
  facebookId = null,
}) {
  const result = await pool.query(
    'INSERT INTO "User" ("fullName", email, "passwordHash", "googleId", "facebookId") VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [fullName, email, passwordHash, googleId, facebookId],
  );
  return result.rows[0];
}

async function findPublicById(id) {
  const result = await pool.query(
    'SELECT id, "fullName", email, "phoneNumber", address, avatar FROM "User" WHERE id = $1',
    [id],
  );
  return result.rows[0] || null;
}

async function findByPhone(phoneNumber) {
  const result = await pool.query(
    'SELECT * FROM "User" WHERE "phoneNumber" = $1 LIMIT 1',
    [phoneNumber],
  );
  return result.rows[0] || null;
}

async function updateProfile({
  id,
  fullName,
  email,
  phoneNumber,
  address,
  avatar,
}) {
  const result = await pool.query(
    'UPDATE "User" SET "fullName" = $2, email = $3, "phoneNumber" = $4, '
      + 'address = $5, avatar = $6 WHERE id = $1 '
      + 'RETURNING id, "fullName", email, "phoneNumber", address, avatar',
    [id, fullName, email, phoneNumber, address, avatar],
  );
  return result.rows[0] || null;
}

async function findProfileStats(userId) {
  const result = await pool.query(
    'SELECT '
      + '(SELECT COUNT(*) FROM "Order" WHERE "userId" = $1) AS "orderCount", '
      + '(SELECT COUNT(*) FROM "Order" WHERE "userId" = $1 '
      + 'AND status = \'pending_confirmation\') AS "pendingCount", '
      + '(SELECT COUNT(*) FROM "Order" WHERE "userId" = $1 '
      + 'AND status = \'waiting_pickup\') AS "waitingPickupCount", '
      + '(SELECT COUNT(*) FROM "Order" WHERE "userId" = $1 '
      + 'AND status = \'shipping\') AS "shippingCount", '
      + '(SELECT COUNT(*) FROM "Order" WHERE "userId" = $1 '
      + 'AND status = \'delivered\') AS "deliveredCount", '
      + '(SELECT COUNT(*) FROM "Order" WHERE "userId" = $1 '
      + 'AND status = \'delivered\' AND "isReviewed" = false) '
      + 'AS "reviewPendingCount", '
      + '(SELECT COUNT(*) FROM "Order" WHERE "userId" = $1 '
      + 'AND status = \'cancelled\') AS "cancelledCount", '
      + '(SELECT COALESCE(SUM(oi.quantity), 0) '
      + 'FROM "OrderItem" oi '
      + 'JOIN "Order" o ON o.id = oi."orderId" '
      + 'WHERE o."userId" = $1) AS "bookCount", '
      + '(SELECT COUNT(*) FROM "Favorite" WHERE "userId" = $1) AS "favoriteCount", '
      + '(SELECT COALESCE(SUM("totalPrice"), 0) FROM "Order" '
      + 'WHERE "userId" = $1) AS "totalSpend", '
      + '(SELECT COALESCE(SUM("totalPrice"), 0) FROM "Order" '
      + 'WHERE "userId" = $1 '
      + 'AND DATE_TRUNC(\'month\', "orderDate") = DATE_TRUNC(\'month\', NOW())) '
      + 'AS "monthlySpend"',
    [userId],
  );
  return result.rows[0] || null;
}

async function updatePasswordByEmail({ email, passwordHash }) {
  const result = await pool.query(
    'UPDATE "User" SET "passwordHash" = $1 WHERE email = $2 RETURNING id',
    [passwordHash, email],
  );
  return result.rows[0] || null;
}

module.exports = {
  findByEmail,
  findByPhone,
  findById,
  findByGoogleId,
  findByFacebookId,
  createUser,
  findPublicById,
  findProfileStats,
  updateProfile,
  updatePasswordByEmail,
};
