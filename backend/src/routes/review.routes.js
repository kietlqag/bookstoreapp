const { Router } = require('express');
const reviewController = require('../controllers/review.controller');

const router = Router();

router.get('/', reviewController.listReviews);
router.post('/', reviewController.createReview);
router.put('/:id', reviewController.updateReview);

module.exports = router;
