const reviewRepository = require('../repositories/review.repository');

function listByBook(bookId) {
  return reviewRepository.findByBookId(bookId);
}

function createReview(payload) {
  return reviewRepository.createReview(payload);
}

module.exports = {
  listByBook,
  createReview,
};
