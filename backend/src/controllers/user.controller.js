const userService = require('../services/user.service');

async function getUser(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const user = await userService.getUserProfile(id);
    return res.json(user);
  } catch (error) {
    if (error.status === 404) {
      return res.status(404).json({ message: error.message });
    }
    return next(error);
  }
}

module.exports = { getUser };
