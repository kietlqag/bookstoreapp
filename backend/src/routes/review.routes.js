const { Router } = require('express');
const reviewController = require('../controllers/review.controller');

const router = Router();

router.get('/', reviewController.listReviews);

module.exports = router;
