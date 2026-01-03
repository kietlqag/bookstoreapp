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
    'SELECT id, "fullName", email, "phoneNumber", address FROM "User" WHERE id = $1',
    [id],
  );
  return result.rows[0] || null;
}

module.exports = {
  findByEmail,
  findById,
  findByGoogleId,
  findByFacebookId,
  createUser,
  findPublicById,
};
