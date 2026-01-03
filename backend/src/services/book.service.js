const bookRepository = require('../repositories/book.repository');

function listBooks() {
  return bookRepository.findAll();
}

async function getBook(id) {
  const book = await bookRepository.findById(id);
  if (!book) {
    const error = new Error('Book not found.');
    error.status = 404;
    throw error;
  }
  return book;
}

module.exports = {
  listBooks,
  getBook,
};
