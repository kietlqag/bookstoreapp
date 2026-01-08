const orderRepository = require('../repositories/order.repository');
const { toOrderResponse } = require('../models/order.model');
const notificationService = require('./notification.service');

async function createOrder({
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
  subtotal,
  shippingFee,
  productDiscount,
  shippingDiscount,
  totalPrice,
  cartItemIds,
  shippingVoucherId,
  productVoucherId,
}) {
  const computedSubtotal = items.reduce((sum, item) => {
    const price = Number(item.price) || 0;
    const qty = Number(item.quantity) || 0;
    return sum + price * qty;
  }, 0);
  const safeSubtotal = Number(subtotal);
  const safeShippingFee = Number(shippingFee) || 0;
  const safeProductDiscount = Number(productDiscount) || 0;
  const safeShippingDiscount = Number(shippingDiscount) || 0;
  const subtotalValue = Number.isFinite(safeSubtotal)
    ? safeSubtotal
    : computedSubtotal;
  const totalValue = Number.isFinite(Number(totalPrice))
    ? Number(totalPrice)
    : subtotalValue - safeProductDiscount + safeShippingFee - safeShippingDiscount;

  const order = await orderRepository.createOrderWithItems({
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
    totalPrice: totalValue,
    subtotal: subtotalValue,
    shippingFee: safeShippingFee,
    productDiscount: safeProductDiscount,
    shippingDiscount: safeShippingDiscount,
    cartItemIds,
    shippingVoucherId,
    productVoucherId,
  });

  // Create notification for order success
  try {
    const itemCount = items.length;
    const firstItem = order.items && order.items.length > 0 ? order.items[0] : null;
    const itemNames = order.items
      ? order.items.slice(0, 3).map((item) => item.bookTitle || 'Sản phẩm').join(', ')
      : '';
    const moreText = itemCount > 3 ? ` và ${itemCount - 3} sản phẩm khác` : '';

    await notificationService.createNotification({
      userId,
      type: 'order',
      title: 'Đặt hàng thành công',
      message: `Đơn hàng #${order.id} đã được đặt thành công. ${itemNames}${moreText}.`,
      relatedId: order.id.toString(),
    });
  } catch (error) {
    // Don't fail order creation if notification fails
    console.error('Failed to create order notification:', error);
  }

  return { id: order.id };
}

async function listOrders(userId) {
  const orders = await orderRepository.findByUserId(userId);
  return orders.map(toOrderResponse);
}

async function updateOrderAddress({
  orderId,
  userId,
  shippingAddressNew,
  shippingAddressOld,
  recipientName,
  phoneNumber,
}) {
  const order = await orderRepository.updateOrderAddress({
    orderId,
    userId,
    shippingAddressNew,
    shippingAddressOld,
    recipientName,
    phoneNumber,
  });
  if (!order) {
    const error = new Error('Order not found.');
    error.status = 404;
    throw error;
  }
  return toOrderResponse({
    ...order,
    items: [],
  });
}

async function updateOrderStatus({ orderId, userId, status }) {
  const order = await orderRepository.updateOrderStatus({
    orderId,
    userId,
    status,
  });
  if (!order) {
    const error = new Error('Order not found.');
    error.status = 404;
    throw error;
  }
  return toOrderResponse({
    ...order,
    items: [],
  });
}

module.exports = {
  createOrder,
  listOrders,
  updateOrderAddress,
  updateOrderStatus,
};
