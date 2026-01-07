const { pool } = require('../config/db');

function mapBookRow(row) {
  return {
    id: row.id,
    title: row.title,
    author: row.author,
    price: row.price,
    discount: row.discount,
    imageUrl: row.imageUrl,
    description: row.description,
    pages: row.pages,
    language: row.language,
    publisher: row.publisher,
    year: row.year,
    categoryName: row.categoryName,
    stockQuantity: row.stockQuantity ?? 0,
    soldQuantity: row.soldQuantity ?? 0,
    rating: row.rating ?? 0,
    reviewCount: row.reviewCount ?? 0,
  };
}

async function findAll() {
  const result = await pool.query(
    'SELECT b.id, b.title, b.author, b.price, b.discount, b."imageUrl", '
      + 'b.description, b.pages, b.language, b.publisher, b.year, b."categoryName", '
      + 'COALESCE(i."totalQuantity", 0) AS "stockQuantity", '
      + 'COALESCE(i."soldQuantity", 0) AS "soldQuantity", '
      + 'COALESCE(r.avg_rating, 0) AS rating, '
      + 'COALESCE(r.review_count, 0) AS "reviewCount" '
      + 'FROM "Book" b '
      + 'LEFT JOIN "Inventory" i ON i."bookId" = b.id '
      + 'LEFT JOIN ('
      + 'SELECT "bookId", AVG(rating) AS avg_rating, COUNT(*) AS review_count '
      + 'FROM "Review" GROUP BY "bookId"'
      + ') r '
      + 'ON r."bookId" = b.id',
  );

  return result.rows.map(mapBookRow);
}

async function findById(id) {
  const result = await pool.query(
    'SELECT b.id, b.title, b.author, b.price, b.discount, b."imageUrl", '
      + 'b.description, b.pages, b.language, b.publisher, b.year, b."categoryName", '
      + 'COALESCE(i."totalQuantity", 0) AS "stockQuantity", '
      + 'COALESCE(i."soldQuantity", 0) AS "soldQuantity", '
      + 'COALESCE(r.avg_rating, 0) AS rating, '
      + 'COALESCE(r.review_count, 0) AS "reviewCount" '
      + 'FROM "Book" b '
      + 'LEFT JOIN "Inventory" i ON i."bookId" = b.id '
      + 'LEFT JOIN ('
      + 'SELECT "bookId", AVG(rating) AS avg_rating, COUNT(*) AS review_count '
      + 'FROM "Review" GROUP BY "bookId"'
      + ') r '
      + 'ON r."bookId" = b.id '
      + 'WHERE b.id = $1 LIMIT 1',
    [id],
  );

  if (result.rows.length === 0) {
    return null;
  }

  return mapBookRow(result.rows[0]);
}

async function searchBooks(query, limit = 5) {
  const searchTerm = `%${query.toLowerCase()}%`;
  const result = await pool.query(
    'SELECT b.id, b.title, b.author, b.price, b.discount, b."imageUrl", '
      + 'b.description, b.pages, b.language, b.publisher, b.year, b."categoryName", '
      + 'COALESCE(i."totalQuantity", 0) AS "stockQuantity", '
      + 'COALESCE(i."soldQuantity", 0) AS "soldQuantity", '
      + 'COALESCE(r.avg_rating, 0) AS rating, '
      + 'COALESCE(r.review_count, 0) AS "reviewCount" '
      + 'FROM "Book" b '
      + 'LEFT JOIN "Inventory" i ON i."bookId" = b.id '
      + 'LEFT JOIN ('
      + 'SELECT "bookId", AVG(rating) AS avg_rating, COUNT(*) AS review_count '
      + 'FROM "Review" GROUP BY "bookId"'
      + ') r '
      + 'ON r."bookId" = b.id '
      + 'WHERE LOWER(b.title) LIKE $1 '
      + '   OR LOWER(b.author) LIKE $1 '
      + '   OR LOWER(b."categoryName") LIKE $1 '
      + '   OR LOWER(b.description) LIKE $1 '
      + 'ORDER BY COALESCE(i."soldQuantity", 0) DESC, COALESCE(r.avg_rating, 0) DESC '
      + 'LIMIT $2',
    [searchTerm, limit],
  );

  return result.rows.map(mapBookRow);
}

async function getPopularBooks(limit = 5) {
  const result = await pool.query(
    'SELECT b.id, b.title, b.author, b.price, b.discount, b."imageUrl", '
      + 'b.description, b.pages, b.language, b.publisher, b.year, b."categoryName", '
      + 'COALESCE(i."totalQuantity", 0) AS "stockQuantity", '
      + 'COALESCE(i."soldQuantity", 0) AS "soldQuantity", '
      + 'COALESCE(r.avg_rating, 0) AS rating, '
      + 'COALESCE(r.review_count, 0) AS "reviewCount" '
      + 'FROM "Book" b '
      + 'LEFT JOIN "Inventory" i ON i."bookId" = b.id '
      + 'LEFT JOIN ('
      + 'SELECT "bookId", AVG(rating) AS avg_rating, COUNT(*) AS review_count '
      + 'FROM "Review" GROUP BY "bookId"'
      + ') r '
      + 'ON r."bookId" = b.id '
      + 'ORDER BY COALESCE(i."soldQuantity", 0) DESC, COALESCE(r.avg_rating, 0) DESC '
      + 'LIMIT $1',
    [limit],
  );

  return result.rows.map(mapBookRow);
}

module.exports = {
  findAll,
  findById,
  searchBooks,
  getPopularBooks,
};
