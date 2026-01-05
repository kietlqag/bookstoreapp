const addressService = require('../services/address.service');

async function listAddresses(req, res, next) {
  try {
    const userId = Number(req.params.userId);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const addresses = await addressService.listAddresses(userId);
    return res.json(addresses);
  } catch (error) {
    return next(error);
  }
}

async function getDefaultAddress(req, res, next) {
  try {
    const userId = Number(req.params.userId);
    if (!Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const address = await addressService.getDefaultAddress(userId);
    return res.json(address);
  } catch (error) {
    return next(error);
  }
}

async function createAddress(req, res, next) {
  try {
    const {
      userId,
      fullName,
      phoneNumber,
      addressLine,
      addressLineNew,
      isDefault,
    } = req.body || {};
    const parsedUserId = Number(userId);
    if (!Number.isInteger(parsedUserId)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }
    if (!fullName || !phoneNumber || !addressLine) {
      return res.status(400).json({ message: 'Missing address fields.' });
    }

    const address = await addressService.createAddress({
      userId: parsedUserId,
      fullName: fullName.toString().trim(),
      phoneNumber: phoneNumber.toString().trim(),
      addressLine: addressLine.toString().trim(),
      addressLineNew: addressLineNew?.toString().trim() || null,
      isDefault: isDefault === true,
    });
    return res.status(201).json(address);
  } catch (error) {
    return next(error);
  }
}

async function setDefaultAddress(req, res, next) {
  try {
    const addressId = Number(req.params.addressId);
    const userId = Number(req.body?.userId);
    if (!Number.isInteger(addressId) || !Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid address payload.' });
    }
    await addressService.setDefaultAddress({ userId, addressId });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
}

async function updateAddress(req, res, next) {
  try {
    const addressId = Number(req.params.addressId);
    const {
      userId,
      fullName,
      phoneNumber,
      addressLine,
      addressLineNew,
      isDefault,
    } = req.body || {};
    const parsedUserId = Number(userId);
    if (!Number.isInteger(addressId) || !Number.isInteger(parsedUserId)) {
      return res.status(400).json({ message: 'Invalid address payload.' });
    }
    if (!fullName || !phoneNumber || !addressLine) {
      return res.status(400).json({ message: 'Missing address fields.' });
    }

    const updated = await addressService.updateAddress({
      addressId,
      userId: parsedUserId,
      fullName: fullName.toString().trim(),
      phoneNumber: phoneNumber.toString().trim(),
      addressLine: addressLine.toString().trim(),
      addressLineNew: addressLineNew?.toString().trim() || null,
      isDefault: isDefault === true,
    });
    return res.json(updated);
  } catch (error) {
    return next(error);
  }
}

async function deleteAddress(req, res, next) {
  try {
    const addressId = Number(req.params.addressId);
    const userId = Number(req.body?.userId);
    if (!Number.isInteger(addressId) || !Number.isInteger(userId)) {
      return res.status(400).json({ message: 'Invalid address payload.' });
    }
    await addressService.deleteAddress({ addressId, userId });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listAddresses,
  getDefaultAddress,
  createAddress,
  setDefaultAddress,
  updateAddress,
  deleteAddress,
};
