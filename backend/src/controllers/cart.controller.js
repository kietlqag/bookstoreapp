const cartService = require('../services/cart.service');

async function listCartItems(req, res, next) {
  try {
    const userId = Number(req.params.userId);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const items = await cartService.listCartItems(userId);
    return res.json(items);
  } catch (error) {
    return next(error);
  }
}

async function addToCart(req, res, next) {
  try {
    const { userId, bookId, quantity } = req.body || {};
    const parsedUserId = Number(userId);
    const parsedBookId = Number(bookId);
    const parsedQty = Number(quantity) || 1;

    if (!Number.isInteger(parsedUserId) || !Number.isInteger(parsedBookId)) {
      return res.status(400).json({ message: 'Invalid cart payload.' });
    }

    const item = await cartService.addToCart({
      userId: parsedUserId,
      bookId: parsedBookId,
      quantity: parsedQty,
    });

    return res.json(item);
  } catch (error) {
    return next(error);
  }
}

async function removeCartItem(req, res, next) {
  try {
    const cartId = Number(req.params.cartId);
    if (!Number.isInteger(cartId)) {
      return res.status(400).json({ message: 'Invalid cart id.' });
    }

    await cartService.removeCartItem(cartId);
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
}

async function updateCartItem(req, res, next) {
  try {
    const cartId = Number(req.params.cartId);
    const quantity = Number(req.body?.quantity);

    if (!Number.isInteger(cartId)) {
      return res.status(400).json({ message: 'Invalid cart id.' });
    }

    if (!Number.isFinite(quantity)) {
      return res.status(400).json({ message: 'Invalid quantity.' });
    }

    const item = await cartService.updateCartQuantity(cartId, quantity);
    if (!item) {
      return res.json({ ok: true, removed: true });
    }
    return res.json(item);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listCartItems,
  addToCart,
  updateCartItem,
  removeCartItem,
};
