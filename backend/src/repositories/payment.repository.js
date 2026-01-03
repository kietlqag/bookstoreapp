const { pool } = require('../config/db');

async function createPayment({ amount, method, paymentStatus }) {
  const result = await pool.query(
    'INSERT INTO "Payment" (amount, method, "paymentStatus") VALUES ($1, $2, $3) RETURNING *',
    [amount, method, paymentStatus],
  );
  return result.rows[0];
}

module.exports = { createPayment };
