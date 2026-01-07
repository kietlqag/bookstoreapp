const { pool } = require('../config/db');

function mapReviewRow(row) {
  return {
    id: row.id,
    bookId: row.bookId,
    userName: row.userName,
    rating: row.rating,
    comment: row.comment,
    images: Array.isArray(row.images) ? row.images : [],
    videos: Array.isArray(row.videos) ? row.videos : [],
    createdAt: row.createdAt,
  };
}

async function findByBookId(bookId) {
  const result = await pool.query(
    'SELECT id, "bookId", "userName", rating, comment, images, videos, "createdAt" '
      + 'FROM "Review" '
      + 'WHERE "bookId" = $1 '
      + 'ORDER BY "createdAt" DESC',
    [bookId],
  );
  return result.rows.map(mapReviewRow);
}

async function createReview({
  orderId,
  orderItemId,
  bookId,
  userId,
  userName,
  rating,
  comment,
  anonymous = false,
  images = [],
  videos = [],
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const orderResult = await client.query(
      'SELECT "userId" FROM "Order" WHERE id = $1',
      [orderId],
    );
    if (orderResult.rowCount === 0) {
      throw new Error('Order not found.');
    }
    const orderUserId = orderResult.rows[0].userId;
    if (orderUserId !== userId) {
      throw new Error('Order does not belong to user.');
    }

    const itemResult = await client.query(
      'SELECT reviewed FROM "OrderItem" WHERE id = $1 AND "orderId" = $2',
      [orderItemId, orderId],
    );
    if (itemResult.rowCount === 0) {
      throw new Error('Order item not found.');
    }
    if (itemResult.rows[0].reviewed) {
      throw new Error('Order item already reviewed.');
    }

    const insertResult = await client.query(
      'INSERT INTO "Review" ("bookId", "orderId", "orderItemId", "userId", "userName", rating, comment, anonymous, images, videos) '
        + 'VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10::jsonb) RETURNING id',
      [
        bookId,
        orderId,
        orderItemId,
        userId,
        anonymous ? null : userName,
        rating,
        comment,
        anonymous,
        JSON.stringify(images),
        JSON.stringify(videos),
      ],
    );

    await client.query(
      'UPDATE "OrderItem" SET reviewed = true WHERE id = $1',
      [orderItemId],
    );

    const remainingResult = await client.query(
      'SELECT COUNT(*) AS remaining FROM "OrderItem" WHERE "orderId" = $1 AND reviewed = false',
      [orderId],
    );
    const remaining = Number(remainingResult.rows[0].remaining ?? 0);
    if (remaining === 0) {
      await client.query(
        'UPDATE "Order" SET "isReviewed" = true WHERE id = $1',
        [orderId],
      );
    }
    await client.query('COMMIT');
    return { reviewId: insertResult.rows[0].id, remaining };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  findByBookId,
  createReview,
};
