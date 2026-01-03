function toOrderResponse(order) {
  return {
    id: order.id,
    status: order.status,
    totalPrice: order.totalPrice,
    orderDate: order.orderDate.toISOString(),
    items: order.items.map((item) => ({
      id: item.id,
      bookId: item.bookId,
      bookTitle: item.bookTitle || '',
      quantity: item.quantity,
      price: item.price,
      bookImageUrl: item.bookImageUrl,
    })),
  };
}

module.exports = { toOrderResponse };
