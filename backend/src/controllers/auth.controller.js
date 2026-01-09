const authService = require('../services/auth.service');

async function register(req, res, next) {
  try {
    const { fullName, email, password } = req.body || {};
    if (!fullName || !email || !password) {
      return res
        .status(400)
        .json({ message: 'Full name, email, and password are required.' });
    }

    const result = await authService.register({ fullName, email, password });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function verify(req, res, next) {
  try {
    const { email, code } = req.body || {};
    if (!email || !code) {
      return res.status(400).json({ message: 'Email and OTP are required.' });
    }

    const result = await authService.verify({ email, code });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function resend(req, res, next) {
  try {
    const { email } = req.body || {};
    if (!email) {
      return res.status(400).json({ message: 'Email is required.' });
    }

    const result = await authService.resendOtp({ email });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const result = await authService.login({ email, password });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function socialRegister(req, res, next) {
  try {
    const { provider, providerUserId, fullName } = req.body || {};
    if (!provider || !providerUserId || !fullName) {
      return res.status(400).json({ message: 'Invalid social payload.' });
    }

    const result = await authService.socialRegister({
      provider,
      providerUserId,
      fullName,
    });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function socialLogin(req, res, next) {
  try {
    const { provider, providerUserId, email } = req.body || {};
    if (!provider || !providerUserId) {
      return res.status(400).json({ message: 'Invalid social payload.' });
    }

    const result = await authService.socialLogin({
      provider,
      providerUserId,
      email,
    });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

function logout(_req, res) {
  res.json({ ok: true });
}

function handleError(error, res, next) {
  const status = error.status || 500;
  if (status >= 500) {
    return next(error);
  }
  return res.status(status).json({ message: error.message });
}

async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body || {};
    if (!email) {
      return res.status(400).json({ message: 'Email is required.' });
    }

    const result = await authService.forgotPassword({ email });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function verifyResetOtp(req, res, next) {
  try {
    const { email, code } = req.body || {};
    if (!email || !code) {
      return res.status(400).json({ message: 'Email and OTP are required.' });
    }

    const result = await authService.verifyResetOtp({ email, code });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { email, code, newPassword } = req.body || {};
    if (!email || !code || !newPassword) {
      return res.status(400).json({ message: 'Email, OTP code, and new password are required.' });
    }

    const result = await authService.resetPassword({ email, code, newPassword });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

async function verifyLoginOtp(req, res, next) {
  try {
    const { email, code } = req.body || {};
    if (!email || !code) {
      return res.status(400).json({ message: 'Email and OTP are required.' });
    }

    const result = await authService.verifyLoginOtp({ email, code });
    return res.json(result);
  } catch (error) {
    return handleError(error, res, next);
  }
}

module.exports = {
  register,
  resend,
  verify,
  login,
  socialRegister,
  socialLogin,
  logout,
  forgotPassword,
  verifyResetOtp,
  resetPassword,
  verifyLoginOtp,
};
