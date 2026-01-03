const { pool } = require('../config/db');

function mapReviewRow(row) {
  return {
    id: row.id,
    bookId: row.bookId,
    userName: row.userName,
    rating: row.rating,
    comment: row.comment,
    createdAt: row.createdAt,
  };
}

async function findByBookId(bookId) {
  const result = await pool.query(
    'SELECT id, "bookId", "userName", rating, comment, "createdAt" '
      + 'FROM "Review" '
      + 'WHERE "bookId" = $1 '
      + 'ORDER BY "createdAt" DESC',
    [bookId],
  );
  return result.rows.map(mapReviewRow);
}

module.exports = {
  findByBookId,
};
