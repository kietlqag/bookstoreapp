const orderRepository = require('../repositories/order.repository');
const { toOrderResponse } = require('../models/order.model');

async function createOrder({
  userId,
  serviceId,
  paymentId,
  shippingAddressNew,
  shippingAddressOld,
  phoneNumber,
  note,
  status,
  items,
  cartItemIds,
  shippingVoucherId,
  productVoucherId,
}) {
  const totalPrice = items.reduce((sum, item) => {
    const price = Number(item.price) || 0;
    const qty = Number(item.quantity) || 0;
    return sum + price * qty;
  }, 0);

  const order = await orderRepository.createOrderWithItems({
    userId,
    serviceId,
    paymentId,
    shippingAddressNew,
    shippingAddressOld,
    phoneNumber,
    note,
    status,
    items,
    totalPrice,
    cartItemIds,
    shippingVoucherId,
    productVoucherId,
  });

  return { id: order.id };
}

async function listOrders(userId) {
  const orders = await orderRepository.findByUserId(userId);
  return orders.map(toOrderResponse);
}

module.exports = {
  createOrder,
  listOrders,
};
