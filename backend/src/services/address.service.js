const addressRepository = require('../repositories/address.repository');

function listAddresses(userId) {
  return addressRepository.findByUserId(userId);
}

function getDefaultAddress(userId) {
  return addressRepository.findDefaultByUserId(userId);
}

async function createAddress(payload) {
  if (payload.isDefault) {
    await addressRepository.clearDefaultForUser(payload.userId);
  }
  return addressRepository.createAddress(payload);
}

async function setDefaultAddress({ userId, addressId }) {
  await addressRepository.clearDefaultForUser(userId);
  await addressRepository.setDefaultAddress(addressId);
}

async function updateAddress(payload) {
  if (payload.isDefault) {
    await addressRepository.clearDefaultForUser(payload.userId);
  }
  return addressRepository.updateAddress(payload);
}

async function deleteAddress({ addressId, userId }) {
  return addressRepository.deleteAddress({ addressId, userId });
}

module.exports = {
  listAddresses,
  getDefaultAddress,
  createAddress,
  setDefaultAddress,
  updateAddress,
  deleteAddress,
};
