const { pool } = require('../config/db');

function mapFlashSaleRow(row) {
  return {
    id: row.id,
    name: row.name,
    startAt: row.startAt,
    endAt: row.endAt,
    discountPercent: parseFloat(row.discountPercent),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function mapBookRow(row) {
  return {
    id: row.id,
    title: row.title,
    author: row.author || '',
    price: parseFloat(row.price || 0),
    discount: parseFloat(row.discount || 0),
    imageUrl: row.imageUrl || '',
    description: row.description || '',
    pages: row.pages,
    language: row.language,
    publisher: row.publisher,
    year: row.year,
    categoryName: row.categoryName || 'Tất cả',
    stockQuantity: parseInt(row.stockQuantity || 0),
    soldQuantity: parseInt(row.soldQuantity || 0),
    rating: parseFloat(row.rating || 0),
    reviewCount: parseInt(row.reviewCount || 0),
  };
}

async function getActiveFlashSale() {
  const now = new Date();
  const query = `
    SELECT *
    FROM "FlashSale"
    WHERE "startAt" <= $1 AND "endAt" >= $1
    ORDER BY "createdAt" DESC
    LIMIT 1
  `;
  const result = await pool.query(query, [now]);
  if (result.rows.length === 0) {
    return null;
  }
  return mapFlashSaleRow(result.rows[0]);
}

async function getFlashSaleBooks(flashSaleId) {
  const query = `
    SELECT 
      b.id, b.title, b.author, b.price, b.discount, b."imageUrl", 
      b.description, b.pages, b.language, b.publisher, b.year, b."categoryName",
      COALESCE(i."totalQuantity", 0) AS "stockQuantity",
      COALESCE(i."soldQuantity", 0) AS "soldQuantity",
      COALESCE(r.avg_rating, 0) AS rating,
      COALESCE(r.review_count, 0) AS "reviewCount"
    FROM "FlashSaleBook" fsb
    INNER JOIN "Book" b ON fsb."book_id" = b.id
    LEFT JOIN "Inventory" i ON i."bookId" = b.id
    LEFT JOIN (
      SELECT "bookId", AVG(rating) AS avg_rating, COUNT(*) AS review_count
      FROM "Review" GROUP BY "bookId"
    ) r ON r."bookId" = b.id
    WHERE fsb."flash_sale_id" = $1
    ORDER BY b.id
  `;
  const result = await pool.query(query, [flashSaleId]);
  return result.rows.map(mapBookRow);
}

async function getAllFlashSales() {
  const query = `
    SELECT *
    FROM "FlashSale"
    ORDER BY "createdAt" DESC
  `;
  const result = await pool.query(query);
  return result.rows.map(mapFlashSaleRow);
}

module.exports = {
  getActiveFlashSale,
  getFlashSaleBooks,
  getAllFlashSales,
};
