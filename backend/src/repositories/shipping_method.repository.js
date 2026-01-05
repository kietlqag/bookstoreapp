const { pool } = require('../config/db');

function mapShippingMethodRow(row) {
  return {
    id: row.id,
    code: row.code,
    title: row.title,
    subtitle: row.subtitle,
    description: row.description,
    fee: Number(row.fee),
    minDays: row.minDays,
    maxDays: row.maxDays,
    sortOrder: row.sortOrder,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function findAll({ activeOnly }) {
  const where = [];
  if (activeOnly) {
    where.push('"isActive" = true');
  }
  const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const result = await pool.query(
    'SELECT id, code, title, subtitle, description, fee, "minDays", "maxDays", '
      + '"sortOrder", "isActive", "createdAt", "updatedAt" '
      + 'FROM "ShippingMethod" '
      + whereClause
      + ' ORDER BY "sortOrder" ASC, id ASC',
  );
  return result.rows.map(mapShippingMethodRow);
}

module.exports = {
  findAll,
};
