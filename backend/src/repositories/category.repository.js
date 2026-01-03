const { pool } = require('../config/db');

function mapCategoryRow(row) {
  return {
    id: row.id,
    name: row.name,
    slug: row.slug,
    description: row.description,
    createdAt: row.createdAt,
  };
}

async function findAll() {
  const result = await pool.query(
    'SELECT id, name, slug, description, "createdAt" '
      + 'FROM "Category" '
      + 'ORDER BY name ASC',
  );
  return result.rows.map(mapCategoryRow);
}

module.exports = {
  findAll,
};
