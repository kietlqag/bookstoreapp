const favoriteRepository = require('../repositories/favorite.repository');

function listFavorites(userId) {
  return favoriteRepository.findByUserId(userId);
}

async function addFavorite(userId, bookId) {
  await favoriteRepository.addFavorite(userId, bookId);
  return { ok: true };
}

async function removeFavorite(userId, bookId) {
  await favoriteRepository.removeFavorite(userId, bookId);
  return { ok: true };
}

module.exports = {
  listFavorites,
  addFavorite,
  removeFavorite,
};
