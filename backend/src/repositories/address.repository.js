const { pool } = require('../config/db');

async function findByUserId(userId) {
  const result = await pool.query(
    'SELECT id, "userId", "fullName", "phoneNumber", "addressLine", "addressLineNew", "isDefault", '
      + '"createdAt", "updatedAt" '
      + 'FROM "UserAddress" '
      + 'WHERE "userId" = $1 '
      + 'ORDER BY "isDefault" DESC, "updatedAt" DESC, id DESC',
    [userId],
  );
  return result.rows;
}

async function findDefaultByUserId(userId) {
  const result = await pool.query(
    'SELECT id, "userId", "fullName", "phoneNumber", "addressLine", "addressLineNew", "isDefault", '
      + '"createdAt", "updatedAt" '
      + 'FROM "UserAddress" '
      + 'WHERE "userId" = $1 AND "isDefault" = true '
      + 'ORDER BY "updatedAt" DESC, id DESC '
      + 'LIMIT 1',
    [userId],
  );
  return result.rows[0] || null;
}

async function clearDefaultForUser(userId) {
  await pool.query(
    'UPDATE "UserAddress" SET "isDefault" = false WHERE "userId" = $1',
    [userId],
  );
}

async function createAddress({
  userId,
  fullName,
  phoneNumber,
  addressLine,
  addressLineNew,
  isDefault,
}) {
  const result = await pool.query(
    'INSERT INTO "UserAddress" ("userId", "fullName", "phoneNumber", "addressLine", "addressLineNew", "isDefault") '
      + 'VALUES ($1, $2, $3, $4, $5, $6) '
      + 'RETURNING id, "userId", "fullName", "phoneNumber", "addressLine", "addressLineNew", "isDefault", "createdAt", "updatedAt"',
    [userId, fullName, phoneNumber, addressLine, addressLineNew, isDefault],
  );
  return result.rows[0] || null;
}

async function setDefaultAddress(addressId) {
  await pool.query(
    'UPDATE "UserAddress" SET "isDefault" = true WHERE id = $1',
    [addressId],
  );
}

async function updateAddress({
  addressId,
  userId,
  fullName,
  phoneNumber,
  addressLine,
  addressLineNew,
  isDefault,
}) {
  const result = await pool.query(
    'UPDATE "UserAddress" '
      + 'SET "fullName" = $3, "phoneNumber" = $4, "addressLine" = $5, '
      + '"addressLineNew" = $6, "isDefault" = $7, "updatedAt" = NOW() '
      + 'WHERE id = $1 AND "userId" = $2 '
      + 'RETURNING id, "userId", "fullName", "phoneNumber", "addressLine", "addressLineNew", "isDefault", "createdAt", "updatedAt"',
    [
      addressId,
      userId,
      fullName,
      phoneNumber,
      addressLine,
      addressLineNew,
      isDefault,
    ],
  );
  return result.rows[0] || null;
}

async function deleteAddress({ addressId, userId }) {
  await pool.query(
    'DELETE FROM "UserAddress" WHERE id = $1 AND "userId" = $2',
    [addressId, userId],
  );
}

module.exports = {
  findByUserId,
  findDefaultByUserId,
  clearDefaultForUser,
  createAddress,
  setDefaultAddress,
  updateAddress,
  deleteAddress,
};
