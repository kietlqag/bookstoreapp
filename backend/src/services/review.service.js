const reviewRepository = require('../repositories/review.repository');

function listByBook(bookId) {
  return reviewRepository.findByBookId(bookId);
}

function listByOrder(orderId, userId) {
  return reviewRepository.findByOrderIdAndUserId(orderId, userId);
}

function createReview(payload) {
  return reviewRepository.createReview(payload);
}

function updateReview(payload) {
  return reviewRepository.updateReview(payload);
}

module.exports = {
  listByBook,
  listByOrder,
  createReview,
  updateReview,
};
