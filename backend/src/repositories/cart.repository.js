const { pool } = require('../config/db');

function mapCartRow(row) {
  const book = {
    id: row.book_id,
    title: row.title,
    author: row.author,
    price: row.price,
    discount: row.discount,
    imageUrl: row.imageUrl,
    description: row.description,
    categoryName: row.categoryName,
    pages: row.pages,
    language: row.language,
    publisher: row.publisher,
    year: row.year,
    stockQuantity: row.stockQuantity,
    soldQuantity: row.soldQuantity,
    rating: row.rating,
    reviewCount: row.reviewCount,
  };

  return {
    id: row.cart_id,
    userId: row.userId,
    bookId: row.bookId,
    quantity: row.quantity,
    book,
  };
}

async function findByUserId(userId) {
  const result = await pool.query(
    'SELECT c.id AS cart_id, c."userId", c."bookId", c.quantity, '
      + 'b.id AS book_id, b.title, b.author, b.price, b.discount, b."imageUrl", '
      + 'b.description, b."categoryName", b.pages, b.language, b.publisher, b.year, '
      + 'COALESCE(inv."totalQuantity", 0) AS "stockQuantity", '
      + 'COALESCE(inv."soldQuantity", 0) AS "soldQuantity", '
      + 'COALESCE(rv.rating, 0) AS rating, COALESCE(rv.review_count, 0) AS "reviewCount" '
      + 'FROM "CartItem" c '
      + 'JOIN "Book" b ON b.id = c."bookId" '
      + 'LEFT JOIN "Inventory" inv ON inv."bookId" = b.id '
      + 'LEFT JOIN ('
      + '  SELECT "bookId", AVG(rating) AS rating, COUNT(*) AS review_count '
      + '  FROM "Review" '
      + '  GROUP BY "bookId"'
      + ') rv ON rv."bookId" = b.id '
      + 'WHERE c."userId" = $1',
    [userId],
  );

  return result.rows.map(mapCartRow);
}

async function findExistingItem(userId, bookId) {
  const result = await pool.query(
    'SELECT * FROM "CartItem" WHERE "userId" = $1 AND "bookId" = $2 LIMIT 1',
    [userId, bookId],
  );
  return result.rows[0] || null;
}

async function getById(id) {
  const result = await pool.query(
    'SELECT c.id AS cart_id, c."userId", c."bookId", c.quantity, '
      + 'b.id AS book_id, b.title, b.author, b.price, b.discount, b."imageUrl", '
      + 'b.description, b."categoryName", b.pages, b.language, b.publisher, b.year, '
      + 'COALESCE(inv."totalQuantity", 0) AS "stockQuantity", '
      + 'COALESCE(inv."soldQuantity", 0) AS "soldQuantity", '
      + 'COALESCE(rv.rating, 0) AS rating, COALESCE(rv.review_count, 0) AS "reviewCount" '
      + 'FROM "CartItem" c '
      + 'JOIN "Book" b ON b.id = c."bookId" '
      + 'LEFT JOIN "Inventory" inv ON inv."bookId" = b.id '
      + 'LEFT JOIN ('
      + '  SELECT "bookId", AVG(rating) AS rating, COUNT(*) AS review_count '
      + '  FROM "Review" '
      + '  GROUP BY "bookId"'
      + ') rv ON rv."bookId" = b.id '
      + 'WHERE c.id = $1 LIMIT 1',
    [id],
  );

  if (result.rows.length === 0) {
    return null;
  }

  return mapCartRow(result.rows[0]);
}

async function createItem({ userId, bookId, quantity }) {
  const result = await pool.query(
    'INSERT INTO "CartItem" ("userId", "bookId", quantity) VALUES ($1, $2, $3) RETURNING id',
    [userId, bookId, quantity],
  );

  return getById(result.rows[0].id);
}

async function updateQuantity(id, quantity) {
  await pool.query(
    'UPDATE "CartItem" SET quantity = $1 WHERE id = $2',
    [quantity, id],
  );

  return getById(id);
}

function removeItem(id) {
  return pool.query('DELETE FROM "CartItem" WHERE id = $1', [id]);
}

module.exports = {
  findByUserId,
  findExistingItem,
  createItem,
  updateQuantity,
  removeItem,
};
