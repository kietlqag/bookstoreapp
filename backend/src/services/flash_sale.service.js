const flashSaleRepository = require('../repositories/flash_sale.repository');

async function getActiveFlashSaleWithBooks() {
  const flashSale = await flashSaleRepository.getActiveFlashSale();
  if (!flashSale) {
    return null;
  }
  
  const books = await flashSaleRepository.getFlashSaleBooks(flashSale.id);
  
  return {
    ...flashSale,
    books: books,
  };
}

module.exports = {
  getActiveFlashSaleWithBooks,
};
