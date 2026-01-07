function toOrderResponse(order) {
  const shippingAddressNew =
    order.shippingAddressNew ?? order.shippingaddressnew ?? null;
  const shippingAddressOld =
    order.shippingAddressOld ?? order.shippingaddressold ?? null;

  return {
    id: order.id,
    status: order.status,
    totalPrice: order.totalPrice,
    recipientName: order.recipientName ?? order.recipientname ?? null,
    phoneNumber: order.phoneNumber ?? order.phonenumber ?? null,
    shippingAddressNew,
    shippingAddressOld,
    subtotal: order.subtotal,
    shippingFee: order.shippingFee,
    productDiscount: order.productDiscount,
    shippingDiscount: order.shippingDiscount,
    orderDate: order.orderDate.toISOString(),
    items: order.items.map((item) => ({
      id: item.id,
      bookId: item.bookId,
      bookTitle: item.bookTitle || '',
      bookAuthor: item.bookAuthor || '',
      reviewed: item.reviewed || false,
      quantity: item.quantity,
      price: item.price,
      bookImageUrl: item.bookImageUrl,
      bookPrice: item.bookPrice,
      bookDiscount: item.bookDiscount,
    })),
    isReviewed: order.isReviewed || false,
  };
}

module.exports = { toOrderResponse };
