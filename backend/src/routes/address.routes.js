const { Router } = require('express');

const addressController = require('../controllers/address.controller');

const router = Router();

router.get('/:userId', addressController.listAddresses);
router.get('/:userId/default', addressController.getDefaultAddress);
router.post('/', addressController.createAddress);
router.patch('/:addressId/default', addressController.setDefaultAddress);
router.patch('/:addressId', addressController.updateAddress);
router.delete('/:addressId', addressController.deleteAddress);

module.exports = router;
