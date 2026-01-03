const userRepository = require('../repositories/user.repository');

async function getUserProfile(id) {
  const user = await userRepository.findPublicById(id);
  if (!user) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }
  return user;
}

module.exports = { getUserProfile };
