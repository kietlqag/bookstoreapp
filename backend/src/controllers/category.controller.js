const categoryService = require('../services/category.service');

async function listCategories(_req, res, next) {
  try {
    const categories = await categoryService.listCategories();
    res.json(categories);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listCategories,
};
