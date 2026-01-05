const { pool } = require('../config/db');

function mapVoucherRow(row) {
  return {
    id: row.id,
    code: row.code,
    title: row.title,
    description: row.description,
    discountType: row.discountType,
    discountValue: Number(row.discountValue),
    maxDiscount: row.maxDiscount === null ? null : Number(row.maxDiscount),
    minOrderValue: Number(row.minOrderValue),
    startAt: row.startAt,
    endAt: row.endAt,
    usageLimit: row.usageLimit,
    usedCount: row.usedCount,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function findAll({ type, activeOnly }) {
  const where = [];
  const params = [];
  if (type) {
    params.push(type);
    where.push(`"discountType" = $${params.length}`);
  }
  if (activeOnly) {
    where.push(
      '"isActive" = true'
        + ' AND ("startAt" IS NULL OR "startAt" <= NOW())'
        + ' AND ("endAt" IS NULL OR "endAt" >= NOW())',
    );
  }
  const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const result = await pool.query(
    'SELECT id, code, title, description, "discountType", "discountValue", '
      + '"maxDiscount", "minOrderValue", "startAt", "endAt", "usageLimit", '
      + '"usedCount", "isActive", "createdAt", "updatedAt" '
      + 'FROM "Voucher" '
      + whereClause
      + ' ORDER BY "createdAt" DESC',
    params,
  );
  return result.rows.map(mapVoucherRow);
}

module.exports = {
  findAll,
};
