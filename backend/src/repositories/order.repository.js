const { pool } = require('../config/db');

async function createOrderWithItems({
  userId,
  serviceId,
  paymentId,
  recipientName,
  shippingAddressNew,
  shippingAddressOld,
  phoneNumber,
  note,
  status,
  items,
  totalPrice,
  subtotal,
  shippingFee,
  productDiscount,
  shippingDiscount,
  cartItemIds,
  shippingVoucherId,
  productVoucherId,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const orderResult = await client.query(
      'INSERT INTO "Order" ("userId", "serviceId", "paymentId", '
        + '"recipientName", "shippingAddressNew", "shippingAddressOld", '
        + '"phoneNumber", note, "totalPrice", status, '
        + 'subtotal, "shippingFee", "productDiscount", "shippingDiscount") '
        + 'VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) '
        + 'RETURNING *',
      [
        userId,
        serviceId,
        paymentId,
        recipientName,
        shippingAddressNew,
        shippingAddressOld,
        phoneNumber,
        note,
        totalPrice,
        status || 'pending_confirmation',
        subtotal || 0,
        shippingFee || 0,
        productDiscount || 0,
        shippingDiscount || 0,
      ],
    );

    const order = orderResult.rows[0];

    for (const item of items) {
      await client.query(
        'INSERT INTO "OrderItem" ("orderId", "bookId", quantity, price) VALUES ($1, $2, $3, $4)',
        [order.id, item.bookId, item.quantity, item.price],
      );
    }

    for (const item of items) {
      const quantity = Number(item.quantity) || 0;
      if (quantity <= 0 || !item.bookId) continue;
      await client.query(
        'UPDATE "Inventory" '
          + 'SET "totalQuantity" = GREATEST("totalQuantity" - $1, 0), '
          + '"remainingQuantity" = GREATEST("remainingQuantity" - $1, 0), '
          + '"soldQuantity" = "soldQuantity" + $1, '
          + '"updatedAt" = NOW() '
          + 'WHERE "bookId" = $2',
        [quantity, item.bookId],
      );
    }

    const voucherIds = [
      shippingVoucherId ? Number(shippingVoucherId) : null,
      productVoucherId ? Number(productVoucherId) : null,
    ].filter((id) => Number.isInteger(id) && id > 0);
    for (const voucherId of [...new Set(voucherIds)]) {
      await client.query(
        'UPDATE "Voucher" SET "usedCount" = "usedCount" + 1, "updatedAt" = NOW() '
          + 'WHERE id = $1',
        [voucherId],
      );
    }

    if (Array.isArray(cartItemIds) && cartItemIds.length > 0) {
      const cleanedIds = cartItemIds
        .map((id) => Number(id))
        .filter((id) => Number.isInteger(id) && id > 0);
      if (cleanedIds.length > 0) {
        await client.query(
          'DELETE FROM "CartItem" WHERE id = ANY($1::int[]) AND "userId" = $2',
          [cleanedIds, userId],
        );
      }
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
    'SELECT oi.*, b.title AS "bookTitle", b."imageUrl" AS "bookImageUrl", '
      + 'b.price AS "bookPrice", b.discount AS "bookDiscount", b.author AS "bookAuthor" '
      + 'FROM "OrderItem" oi '
      + 'LEFT JOIN "Book" b ON b.id = oi."bookId" '
      + 'WHERE oi."orderId" = ANY($1::int[])',
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

async function updateOrderAddress({
  orderId,
  userId,
  shippingAddressNew,
  shippingAddressOld,
  recipientName,
  phoneNumber,
}) {
  const result = await pool.query(
    'UPDATE "Order" SET "shippingAddressNew" = $1, "shippingAddressOld" = $2, '
      + '"recipientName" = $3, "phoneNumber" = $4 '
      + 'WHERE id = $5 AND "userId" = $6 '
      + 'RETURNING *',
    [
      shippingAddressNew,
      shippingAddressOld,
      recipientName,
      phoneNumber,
      orderId,
      userId,
    ],
  );
  return result.rows[0] || null;
}

async function updateOrderStatus({ orderId, userId, status }) {
  const result = await pool.query(
    'UPDATE "Order" SET status = $1 WHERE id = $2 AND "userId" = $3 RETURNING *',
    [status, orderId, userId],
  );
  return result.rows[0] || null;
}

module.exports = {
  createOrderWithItems,
  findByUserId,
  updateOrderAddress,
  updateOrderStatus,
};
