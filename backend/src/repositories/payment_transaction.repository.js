const { pool } = require('../config/db');

function mapTransactionRow(row) {
  return {
    id: row.id,
    orderId: row.orderId,
    methodCode: row.methodCode,
    provider: row.provider,
    amount: Number(row.amount),
    currency: row.currency,
    status: row.status,
    txnRef: row.txnRef,
    providerTxnId: row.providerTxnId,
    paymentUrl: row.paymentUrl,
    qrContent: row.qrContent,
    orderPayload: row.orderPayload,
    rawPayload: row.rawPayload,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function createTransaction({
  orderId,
  methodCode,
  provider,
  amount,
  currency,
  status,
  txnRef,
  providerTxnId,
  paymentUrl,
  qrContent,
  orderPayload,
  rawPayload,
}) {
  const result = await pool.query(
    'INSERT INTO "PaymentTransaction" '
      + '("orderId", "methodCode", provider, amount, currency, status, '
      + '"txnRef", "providerTxnId", "paymentUrl", "qrContent", "orderPayload", "rawPayload") '
      + 'VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *',
    [
      orderId ?? null,
      methodCode,
      provider,
      amount,
      currency ?? 'VND',
      status ?? 'pending',
      txnRef ?? null,
      providerTxnId ?? null,
      paymentUrl ?? null,
      qrContent ?? null,
      orderPayload ?? null,
      rawPayload ?? null,
    ],
  );
  return mapTransactionRow(result.rows[0]);
}

async function updateTransaction(id, fields) {
  const updates = [];
  const values = [];
  let index = 1;

  const pushField = (key, value) => {
    updates.push(`"${key}" = $${index}`);
    values.push(value);
    index += 1;
  };

  if (Object.prototype.hasOwnProperty.call(fields, 'status')) {
    pushField('status', fields.status);
  }
  if (Object.prototype.hasOwnProperty.call(fields, 'providerTxnId')) {
    pushField('providerTxnId', fields.providerTxnId);
  }
  if (Object.prototype.hasOwnProperty.call(fields, 'paymentUrl')) {
    pushField('paymentUrl', fields.paymentUrl);
  }
  if (Object.prototype.hasOwnProperty.call(fields, 'qrContent')) {
    pushField('qrContent', fields.qrContent);
  }
  if (Object.prototype.hasOwnProperty.call(fields, 'orderPayload')) {
    pushField('orderPayload', fields.orderPayload);
  }
  if (Object.prototype.hasOwnProperty.call(fields, 'rawPayload')) {
    pushField('rawPayload', fields.rawPayload);
  }
  if (Object.prototype.hasOwnProperty.call(fields, 'orderId')) {
    pushField('orderId', fields.orderId);
  }

  if (!updates.length) {
    return null;
  }

  pushField('updatedAt', new Date());
  values.push(id);

  const result = await pool.query(
    `UPDATE "PaymentTransaction" SET ${updates.join(', ')} WHERE id = $${
      index
    } RETURNING *`,
    values,
  );
  return result.rows[0] ? mapTransactionRow(result.rows[0]) : null;
}

async function updateByTxnRef(txnRef, fields) {
  const result = await pool.query(
    'SELECT id FROM "PaymentTransaction" WHERE "txnRef" = $1 LIMIT 1',
    [txnRef],
  );
  if (!result.rows[0]) return null;
  return updateTransaction(result.rows[0].id, fields);
}

async function findByTxnRef(txnRef) {
  const result = await pool.query(
    'SELECT * FROM "PaymentTransaction" WHERE "txnRef" = $1 LIMIT 1',
    [txnRef],
  );
  return result.rows[0] ? mapTransactionRow(result.rows[0]) : null;
}

module.exports = {
  createTransaction,
  updateTransaction,
  updateByTxnRef,
  findByTxnRef,
};
