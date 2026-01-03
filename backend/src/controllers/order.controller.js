const orderService = require('../services/order.service');

async function createOrder(req, res, next) {
  try {
    const {
      userId,
      serviceId,
      paymentId,
      shippingAddress,
      phoneNumber,
      note,
      orderItems,
    } = req.body || {};

    const parsedUserId = Number(userId);
    if (!Number.isInteger(parsedUserId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const items = Array.isArray(orderItems) ? orderItems : [];
    const order = await orderService.createOrder({
      userId: parsedUserId,
      serviceId: Number(serviceId) || null,
      paymentId: Number(paymentId) || null,
      shippingAddress: shippingAddress || null,
      phoneNumber: phoneNumber || null,
      note: note || null,
      items: items.map((item) => ({
        bookId: Number(item.bookId) || 0,
        quantity: Number(item.quantity) || 0,
        price: Number(item.price) || 0,
      })),
    });

    res.json(order);
  } catch (error) {
    next(error);
  }
}

async function listOrders(req, res, next) {
  try {
    const userId = Number(req.params.userId);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const orders = await orderService.listOrders(userId);
    return res.json(orders);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createOrder,
  listOrders,
};
