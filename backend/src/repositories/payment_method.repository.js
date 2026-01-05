const { pool } = require('../config/db');

function mapPaymentMethodRow(row) {
  return {
    id: row.id,
    code: row.code,
    title: row.title,
    provider: row.provider,
    methodType: row.methodType,
    isActive: row.isActive,
    sortOrder: row.sortOrder,
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
    'SELECT id, code, title, provider, "methodType", "isActive", "sortOrder", '
      + '"createdAt", "updatedAt" '
      + 'FROM "PaymentMethod" '
      + whereClause
      + ' ORDER BY "sortOrder" ASC, id ASC',
  );
  return result.rows.map(mapPaymentMethodRow);
}

async function findByCode(code) {
  const result = await pool.query(
    'SELECT id, code, title, provider, "methodType", "isActive", "sortOrder", '
      + '"createdAt", "updatedAt" '
      + 'FROM "PaymentMethod" WHERE code = $1 LIMIT 1',
    [code],
  );
  return result.rows[0] ? mapPaymentMethodRow(result.rows[0]) : null;
}

module.exports = {
  findAll,
  findByCode,
};
