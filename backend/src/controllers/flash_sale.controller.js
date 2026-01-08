const flashSaleService = require('../services/flash_sale.service');

async function getActiveFlashSale(req, res, next) {
  try {
    const flashSale = await flashSaleService.getActiveFlashSaleWithBooks();
    if (!flashSale) {
      return res.status(404).json({ message: 'Không có flash sale đang diễn ra.' });
    }
    res.json(flashSale);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getActiveFlashSale,
};
