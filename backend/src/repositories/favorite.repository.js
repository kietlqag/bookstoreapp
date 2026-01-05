const { pool } = require('../config/db');

async function findByUserId(userId) {
  const result = await pool.query(
    'SELECT "bookId" FROM "Favorite" WHERE "userId" = $1 ORDER BY "createdAt" DESC',
    [userId],
  );
  return result.rows.map((row) => row.bookId);
}

async function findExisting(userId, bookId) {
  const result = await pool.query(
    'SELECT id FROM "Favorite" WHERE "userId" = $1 AND "bookId" = $2 LIMIT 1',
    [userId, bookId],
  );
  return result.rows[0] || null;
}

async function addFavorite(userId, bookId) {
  const result = await pool.query(
    'INSERT INTO "Favorite" ("userId", "bookId") VALUES ($1, $2) '
      + 'ON CONFLICT ("userId", "bookId") DO NOTHING '
      + 'RETURNING id',
    [userId, bookId],
  );
  return result.rows[0] || null;
}

async function removeFavorite(userId, bookId) {
  await pool.query(
    'DELETE FROM "Favorite" WHERE "userId" = $1 AND "bookId" = $2',
    [userId, bookId],
  );
}

module.exports = {
  findByUserId,
  findExisting,
  addFavorite,
  removeFavorite,
};
