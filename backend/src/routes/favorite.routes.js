const { Router } = require('express');

const favoriteController = require('../controllers/favorite.controller');

const router = Router();

router.get('/:userId', favoriteController.listFavorites);
router.post('/', favoriteController.addFavorite);
router.delete('/:userId/:bookId', favoriteController.removeFavorite);

module.exports = router;
