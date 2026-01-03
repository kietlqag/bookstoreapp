const reviewRepository = require('../repositories/review.repository');

function listByBook(bookId) {
  return reviewRepository.findByBookId(bookId);
}

module.exports = {
  listByBook,
};
