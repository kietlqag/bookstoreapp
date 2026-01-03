const { Router } = require('express');
const bookController = require('../controllers/book.controller');

const router = Router();

router.get('/', bookController.listBooks);
router.get('/:id', bookController.getBook);

module.exports = router;
