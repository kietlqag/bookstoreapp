const reviewService = require('../services/review.service');

async function listReviews(req, res, next) {
  try {
    const bookId = Number(req.query.bookId);
    if (!Number.isInteger(bookId)) {
      return res.status(400).json({ message: 'Invalid book id.' });
    }
    const reviews = await reviewService.listByBook(bookId);
    return res.json(reviews);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listReviews,
};
