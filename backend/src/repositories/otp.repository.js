const { pool } = require('../config/db');

function deleteByEmail(email) {
  return pool.query('DELETE FROM "OtpVerification" WHERE email = $1', [email]);
}

async function createOtp({ email, fullName, passwordHash, code, expiresAt }) {
  const result = await pool.query(
    'INSERT INTO "OtpVerification" (email, "fullName", "passwordHash", code, "expiresAt") VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [email, fullName, passwordHash, code, expiresAt],
  );
  return result.rows[0];
}

async function createResetPasswordOtp({ email, code, expiresAt }) {
  // For reset password, we don't need fullName or passwordHash, but schema requires them
  // Use empty string as placeholder
  const result = await pool.query(
    'INSERT INTO "OtpVerification" (email, "fullName", "passwordHash", code, "expiresAt") VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [email, '', '', code, expiresAt],
  );
  return result.rows[0];
}

async function findLatestByEmail(email) {
  const result = await pool.query(
    'SELECT * FROM "OtpVerification" WHERE email = $1 ORDER BY "createdAt" DESC LIMIT 1',
    [email],
  );
  return result.rows[0] || null;
}

function markVerified(id) {
  return pool.query(
    'UPDATE "OtpVerification" SET "verifiedAt" = NOW() WHERE id = $1',
    [id],
  );
}

function incrementAttempts(id) {
  return pool.query(
    'UPDATE "OtpVerification" SET attempts = attempts + 1 WHERE id = $1',
    [id],
  );
}

function updateOtp(id, { code, expiresAt }) {
  return pool.query(
    'UPDATE "OtpVerification" SET code = $1, "expiresAt" = $2, attempts = 0 WHERE id = $3',
    [code, expiresAt, id],
  );
}

module.exports = {
  deleteByEmail,
  createOtp,
  createResetPasswordOtp,
  findLatestByEmail,
  markVerified,
  incrementAttempts,
  updateOtp,
};
