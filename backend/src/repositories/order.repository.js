const { pool } = require('../config/db');

async function createOrderWithItems({
  userId,
  serviceId,
  paymentId,
  shippingAddress,
  phoneNumber,
  note,
  items,
  totalPrice,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const orderResult = await client.query(
      'INSERT INTO "Order" ("userId", "serviceId", "paymentId", "shippingAddress", "phoneNumber", note, "totalPrice") '
        + 'VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
      [
        userId,
        serviceId,
        paymentId,
        shippingAddress,
        phoneNumber,
        note,
        totalPrice,
      ],
    );

    const order = orderResult.rows[0];

    for (const item of items) {
      await client.query(
        'INSERT INTO "OrderItem" ("orderId", "bookId", quantity, price) VALUES ($1, $2, $3, $4)',
        [order.id, item.bookId, item.quantity, item.price],
      );
    }

    await client.query('COMMIT');
    return order;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function findByUserId(userId) {
  const ordersResult = await pool.query(
    'SELECT * FROM "Order" WHERE "userId" = $1 ORDER BY "orderDate" DESC',
    [userId],
  );
  const orders = ordersResult.rows;

  if (orders.length === 0) {
    return [];
  }

  const orderIds = orders.map((order) => order.id);
  const itemsResult = await pool.query(
    'SELECT * FROM "OrderItem" WHERE "orderId" = ANY($1::int[])',
    [orderIds],
  );

  const itemsByOrder = new Map();
  for (const item of itemsResult.rows) {
    const list = itemsByOrder.get(item.orderId) || [];
    list.push(item);
    itemsByOrder.set(item.orderId, list);
  }

  return orders.map((order) => ({
    ...order,
    items: itemsByOrder.get(order.id) || [],
  }));
}

module.exports = {
  createOrderWithItems,
  findByUserId,
};
