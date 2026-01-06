const { pool } = require('../config/db');

async function createOtp({ userId, type, value, code, expiresAt }) {
  const result = await pool.query(
    'INSERT INTO "UserContactOtp" ("userId", type, value, code, "expiresAt") '
      + 'VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [userId, type, value, code, expiresAt],
  );
  return result.rows[0] || null;
}

async function findLatestOtp({ userId, type, value }) {
  const result = await pool.query(
    'SELECT * FROM "UserContactOtp" '
      + 'WHERE "userId" = $1 AND type = $2 AND value = $3 '
      + 'ORDER BY "createdAt" DESC LIMIT 1',
    [userId, type, value],
  );
  return result.rows[0] || null;
}

async function markVerified(id) {
  const result = await pool.query(
    'UPDATE "UserContactOtp" SET "verifiedAt" = NOW() WHERE id = $1 RETURNING *',
    [id],
  );
  return result.rows[0] || null;
}

module.exports = {
  createOtp,
  findLatestOtp,
  markVerified,
};
