const favoriteService = require('../services/favorite.service');

async function listFavorites(req, res, next) {
  try {
    const userId = Number(req.params.userId);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const items = await favoriteService.listFavorites(userId);
    return res.json(items);
  } catch (error) {
    return next(error);
  }
}

async function addFavorite(req, res, next) {
  try {
    const { userId, bookId } = req.body || {};
    const parsedUserId = Number(userId);
    const parsedBookId = Number(bookId);
    if (!Number.isInteger(parsedUserId) || !Number.isInteger(parsedBookId)) {
      return res.status(400).json({ message: 'Invalid favorite payload.' });
    }

    await favoriteService.addFavorite(parsedUserId, parsedBookId);
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
}

async function removeFavorite(req, res, next) {
  try {
    const userId = Number(req.params.userId);
    const bookId = Number(req.params.bookId);
    if (!Number.isInteger(userId) || !Number.isInteger(bookId)) {
      return res.status(400).json({ message: 'Invalid favorite payload.' });
    }

    await favoriteService.removeFavorite(userId, bookId);
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listFavorites,
  addFavorite,
  removeFavorite,
};
