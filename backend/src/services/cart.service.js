const cartRepository = require('../repositories/cart.repository');

function listCartItems(userId) {
  return cartRepository.findByUserId(userId);
}

async function addToCart({ userId, bookId, quantity }) {
  const existing = await cartRepository.findExistingItem(userId, bookId);
  if (existing) {
    return cartRepository.updateQuantity(
      existing.id,
      existing.quantity + (quantity || 1),
    );
  }
  return cartRepository.createItem({ userId, bookId, quantity: quantity || 1 });
}

async function updateCartQuantity(cartId, quantity) {
  if (quantity <= 0) {
    await cartRepository.removeItem(cartId);
    return null;
  }
  return cartRepository.updateQuantity(cartId, quantity);
}

async function removeCartItem(cartId) {
  await cartRepository.removeItem(cartId);
  return { ok: true };
}

module.exports = {
  listCartItems,
  addToCart,
  updateCartQuantity,
  removeCartItem,
};
