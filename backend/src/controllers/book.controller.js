const bookService = require('../services/book.service');

async function listBooks(_req, res, next) {
  try {
    const books = await bookService.listBooks();
    res.json(books);
  } catch (error) {
    next(error);
  }
}

async function getBook(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid book id.' });
    }

    const book = await bookService.getBook(id);
    return res.json(book);
  } catch (error) {
    if (error.status === 404) {
      return res.status(404).json({ message: error.message });
    }
    return next(error);
  }
}

module.exports = {
  listBooks,
  getBook,
};
