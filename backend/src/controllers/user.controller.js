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

async function getUserSummary(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const summary = await userService.getUserSummary(id);
    return res.json(summary);
  } catch (error) {
    if (error.status === 404) {
      return res.status(404).json({ message: error.message });
    }
    return next(error);
  }
}

async function updateUser(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    const updated = await userService.updateUserProfile(id, req.body || {});
    return res.json(updated);
  } catch (error) {
    if (error.status === 404) {
      return res.status(404).json({ message: error.message });
    }
    return next(error);
  }
}

async function requestEmailChange(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }
    const email = req.body?.email?.toString() || '';
    const result = await userService.requestEmailChange(id, email);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

async function verifyEmailChange(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }
    const email = req.body?.email?.toString() || '';
    const code = req.body?.code?.toString() || '';
    const result = await userService.verifyEmailChange(id, email, code);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

async function requestPhoneChange(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }
    const phoneNumber = req.body?.phoneNumber?.toString() || '';
    const result = await userService.requestPhoneChange(id, phoneNumber);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

async function verifyPhoneChange(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }
    const phoneNumber = req.body?.phoneNumber?.toString() || '';
    const code = req.body?.code?.toString() || '';
    const result = await userService.verifyPhoneChange(id, phoneNumber, code);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

async function changePassword(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    // Verify that the authenticated user is changing their own password
    if (req.user && req.user.id !== id) {
      return res.status(403).json({ message: 'You can only change your own password.' });
    }

    const currentPassword = req.body?.currentPassword?.toString() || '';
    const newPassword = req.body?.newPassword?.toString() || '';

    const result = await userService.changePassword(id, currentPassword, newPassword);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

async function requestAccountDeletion(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    // Verify that the authenticated user is deleting their own account
    if (req.user && req.user.id !== id) {
      return res.status(403).json({ message: 'You can only delete your own account.' });
    }

    const result = await userService.requestAccountDeletion(id);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ 
        message: error.message,
        code: error.code,
      });
    }
    return next(error);
  }
}

async function verifyAccountDeletion(req, res, next) {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ message: 'Invalid user id.' });
    }

    // Verify that the authenticated user is deleting their own account
    if (req.user && req.user.id !== id) {
      return res.status(403).json({ message: 'You can only delete your own account.' });
    }

    const code = req.body?.code?.toString() || '';

    const result = await userService.verifyAccountDeletion(id, code);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

async function enableTwoFactor(req, res, next) {
  try {
    const { id } = req.params;
    const userId = parseInt(id, 10);
    if (isNaN(userId)) {
      return res.status(400).json({ message: 'Invalid user ID.' });
    }

    // Verify that the authenticated user is enabling 2FA for their own account
    if (req.user && req.user.id !== userId) {
      return res.status(403).json({ message: 'You can only enable 2FA for your own account.' });
    }

    const result = await userService.enableTwoFactor(userId);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

async function disableTwoFactor(req, res, next) {
  try {
    const { id } = req.params;
    const userId = parseInt(id, 10);
    if (isNaN(userId)) {
      return res.status(400).json({ message: 'Invalid user ID.' });
    }

    // Verify that the authenticated user is disabling 2FA for their own account
    if (req.user && req.user.id !== userId) {
      return res.status(403).json({ message: 'You can only disable 2FA for your own account.' });
    }

    const result = await userService.disableTwoFactor(userId);
    return res.json(result);
  } catch (error) {
    if (error.status) {
      return res.status(error.status).json({ message: error.message });
    }
    return next(error);
  }
}

module.exports = {
  getUser,
  getUserSummary,
  updateUser,
  requestEmailChange,
  verifyEmailChange,
  requestPhoneChange,
  verifyPhoneChange,
  changePassword,
  requestAccountDeletion,
  verifyAccountDeletion,
  enableTwoFactor,
  disableTwoFactor,
};
