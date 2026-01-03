const categoryRepository = require('../repositories/category.repository');

function listCategories() {
  return categoryRepository.findAll();
}

module.exports = {
  listCategories,
};
