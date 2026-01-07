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

function mapOrderReviewRow(row) {
  return {
    id: row.id,
    orderItemId: row.orderItemId,
    bookId: row.bookId,
    userName: row.userName,
    rating: row.rating,
    comment: row.comment,
    anonymous: row.anonymous,
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

async function findByOrderIdAndUserId(orderId, userId) {
  const orderResult = await pool.query(
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

  const result = await pool.query(
    'SELECT id, "orderItemId", "bookId", "userName", rating, comment, '
      + 'anonymous, images, videos, "createdAt" '
      + 'FROM "Review" '
      + 'WHERE "orderId" = $1 AND "userId" = $2 '
      + 'ORDER BY "createdAt" DESC',
    [orderId, userId],
  );
  return result.rows.map(mapOrderReviewRow);
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

async function updateReview({
  reviewId,
  userId,
  userName,
  rating,
  comment,
  anonymous = false,
  images = [],
  videos = [],
}) {
  const result = await pool.query(
    'SELECT id, "userId" FROM "Review" WHERE id = $1 LIMIT 1',
    [reviewId],
  );
  if (result.rowCount === 0) {
    throw new Error('Review not found.');
  }
  if (result.rows[0].userId !== userId) {
    throw new Error('Review does not belong to user.');
  }

  const updateResult = await pool.query(
    'UPDATE "Review" SET rating = $1, comment = $2, anonymous = $3, '
      + '"userName" = $4, images = $5::jsonb, videos = $6::jsonb '
      + 'WHERE id = $7 RETURNING id',
    [
      rating,
      comment,
      anonymous,
      anonymous ? null : userName,
      JSON.stringify(images),
      JSON.stringify(videos),
      reviewId,
    ],
  );

  return { reviewId: updateResult.rows[0].id };
}

module.exports = {
  findByBookId,
  findByOrderIdAndUserId,
  createReview,
  updateReview,
};
