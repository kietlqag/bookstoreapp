const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const userRepository = require('../repositories/user.repository');
const otpRepository = require('../repositories/otp.repository');
const { sendOtpEmail } = require('../config/mailer');

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret';
const OTP_EXPIRY_MINUTES = 10;
const OTP_MAX_ATTEMPTS = 5;

async function register({ fullName, email, password }) {
  console.log(`Register request for ${email}`);
  const existing = await userRepository.findByEmail(email);
  if (existing) {
    const error = new Error('Email already in use.');
    error.status = 409;
    throw error;
  }

  await otpRepository.deleteByEmail(email);

  const passwordHash = await bcrypt.hash(password, 10);
  const code = generateOtpCode();
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  await otpRepository.createOtp({
    email,
    fullName,
    passwordHash,
    code,
    expiresAt,
  });

  try {
    await sendOtpEmail({ to: email, code });
    console.log(`OTP email sent to ${email}`);
  } catch (emailError) {
    console.error(`Failed to send OTP email to ${email}:`, emailError);
    if (emailError.message && emailError.message.includes('App Password')) {
      throw emailError; // Re-throw the improved error message
    }
    const error = new Error('Không thể gửi email. Vui lòng kiểm tra cấu hình email server hoặc thử lại sau.');
    error.status = 500;
    throw error;
  }

  return { ok: true };
}

async function resendOtp({ email }) {
  const record = await otpRepository.findLatestByEmail(email);
  if (!record) {
    const error = new Error('OTP not found.');
    error.status = 404;
    throw error;
  }

  if (record.verifiedAt) {
    const error = new Error('OTP already used.');
    error.status = 409;
    throw error;
  }

  const code = generateOtpCode();
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  await otpRepository.updateOtp(record.id, { code, expiresAt });
  
  try {
    await sendOtpEmail({ to: email, code });
    console.log(`Resend OTP email sent to ${email}`);
  } catch (emailError) {
    console.error(`Failed to send resend OTP email to ${email}:`, emailError);
    if (emailError.message && emailError.message.includes('App Password')) {
      throw emailError; // Re-throw the improved error message
    }
    const error = new Error('Không thể gửi email. Vui lòng kiểm tra cấu hình email server hoặc thử lại sau.');
    error.status = 500;
    throw error;
  }

  return { ok: true };
}

async function verify({ email, code }) {
  const record = await otpRepository.findLatestByEmail(email);
  if (!record) {
    const error = new Error('OTP not found.');
    error.status = 404;
    throw error;
  }

  if (record.verifiedAt) {
    const error = new Error('OTP already used.');
    error.status = 409;
    throw error;
  }

  if (record.expiresAt < new Date()) {
    const error = new Error('OTP expired.');
    error.status = 410;
    throw error;
  }

  if (record.attempts >= OTP_MAX_ATTEMPTS) {
    const error = new Error('Too many attempts.');
    error.status = 429;
    throw error;
  }

  if (record.code !== code) {
    await otpRepository.incrementAttempts(record.id);
    const error = new Error('Invalid OTP.');
    error.status = 400;
    throw error;
  }

  const user = await userRepository.createUser({
    fullName: record.fullName,
    email: record.email,
    passwordHash: record.passwordHash,
  });

  await otpRepository.markVerified(record.id);

  return signSession(user);
}

async function login({ email, password }) {
  const user = await userRepository.findByEmail(email);
  if (!user || !user.passwordHash) {
    const error = new Error('Invalid credentials.');
    error.status = 401;
    throw error;
  }

  const matches = await bcrypt.compare(password, user.passwordHash);
  if (!matches) {
    const error = new Error('Invalid credentials.');
    error.status = 401;
    throw error;
  }

  return signSession(user);
}

async function socialRegister({ provider, providerUserId, fullName }) {
  const lookup = getSocialLookup(provider, providerUserId);
  const existingByProvider = await lookup.findByProviderId(providerUserId);
  if (existingByProvider) {
    return signSession(existingByProvider);
  }

  const user = await userRepository.createUser({
    fullName,
    email: null,
    passwordHash: null,
    googleId: lookup.googleId,
    facebookId: lookup.facebookId,
  });

  return signSession(user);
}

async function socialLogin({ provider, providerUserId }) {
  const lookup = getSocialLookup(provider, providerUserId);
  const user = await lookup.findByProviderId(providerUserId);
  if (!user) {
    const error = new Error('Account not found. Please register first.');
    error.status = 404;
    throw error;
  }

  return signSession(user);
}

function signSession(user) {
  const token = jwt.sign({ sub: user.id, role: user.role }, JWT_SECRET, {
    expiresIn: '7d',
  });

  return { token, role: user.role, userId: user.id.toString() };
}

function generateOtpCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function getSocialLookup(provider, providerUserId) {
  if (provider === 'google') {
    return {
      findByProviderId: userRepository.findByGoogleId,
      googleId: providerUserId,
      facebookId: null,
    };
  }
  if (provider === 'facebook') {
    return {
      findByProviderId: userRepository.findByFacebookId,
      googleId: null,
      facebookId: providerUserId,
    };
  }
  const error = new Error('Unsupported social provider.');
  error.status = 400;
  throw error;
}

async function forgotPassword({ email }) {
  // Check if user exists
  const user = await userRepository.findByEmail(email);
  if (!user) {
    const error = new Error('Email không tồn tại trong hệ thống.');
    error.status = 404;
    throw error;
  }

  // Check if user has password (not social login only)
  if (!user.passwordHash) {
    const error = new Error('Tài khoản này sử dụng đăng nhập bằng tài khoản xã hội. Không thể đặt lại mật khẩu.');
    error.status = 400;
    throw error;
  }

  // Delete any existing OTP for this email
  await otpRepository.deleteByEmail(email);

  // Generate new OTP
  const code = generateOtpCode();
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  // Create OTP record for reset password (without passwordHash)
  await otpRepository.createResetPasswordOtp({
    email,
    code,
    expiresAt,
  });

  // Send OTP email
  try {
    await sendOtpEmail({ to: email, code });
    console.log(`Reset password OTP email sent to ${email}`);
  } catch (emailError) {
    // If email sending fails, still return success to user (security best practice)
    // But log the error for admin
    console.error(`Failed to send reset password email to ${email}:`, emailError);
    // Re-throw with user-friendly message
    if (emailError.message && emailError.message.includes('App Password')) {
      throw emailError; // Re-throw the improved error message
    }
    const error = new Error('Không thể gửi email. Vui lòng kiểm tra cấu hình email server hoặc thử lại sau.');
    error.status = 500;
    throw error;
  }

  return { ok: true };
}

async function verifyResetOtp({ email, code }) {
  const record = await otpRepository.findLatestByEmail(email);
  if (!record) {
    const error = new Error('OTP not found. Please request a new one.');
    error.status = 404;
    throw error;
  }

  if (record.verifiedAt) {
    const error = new Error('OTP already used. Please request a new one.');
    error.status = 400;
    throw error;
  }

  if (new Date(record.expiresAt).getTime() < Date.now()) {
    const error = new Error('OTP expired. Please request a new one.');
    error.status = 400;
    throw error;
  }

  if (record.code !== code) {
    await otpRepository.incrementAttempts(record.id);
    if (record.attempts + 1 >= OTP_MAX_ATTEMPTS) {
      await otpRepository.deleteByEmail(email);
      const error = new Error('Too many failed attempts. Please request a new OTP.');
      error.status = 429;
      throw error;
    }
    const error = new Error('Invalid OTP code.');
    error.status = 400;
    throw error;
  }

  // Mark OTP as verified
  await otpRepository.markVerified(record.id);

  return { ok: true };
}

async function resetPassword({ email, code, newPassword }) {
  // Verify OTP first
  const record = await otpRepository.findLatestByEmail(email);
  if (!record) {
    const error = new Error('OTP not found. Please request a new one.');
    error.status = 404;
    throw error;
  }

  if (record.verifiedAt) {
    const error = new Error('OTP already used. Please request a new one.');
    error.status = 400;
    throw error;
  }

  if (new Date(record.expiresAt).getTime() < Date.now()) {
    const error = new Error('OTP expired. Please request a new one.');
    error.status = 400;
    throw error;
  }

  if (record.code !== code) {
    await otpRepository.incrementAttempts(record.id);
    if (record.attempts + 1 >= OTP_MAX_ATTEMPTS) {
      await otpRepository.deleteByEmail(email);
      const error = new Error('Too many failed attempts. Please request a new OTP.');
      error.status = 429;
      throw error;
    }
    const error = new Error('Invalid OTP code.');
    error.status = 400;
    throw error;
  }

  // Mark OTP as verified
  await otpRepository.markVerified(record.id);

  // Update password
  const passwordHash = await bcrypt.hash(newPassword, 10);
  const updated = await userRepository.updatePasswordByEmail({ email, passwordHash });
  if (!updated) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }

  // Delete OTP record after successful password reset
  await otpRepository.deleteByEmail(email);

  return { ok: true };
}

module.exports = {
  register,
  resendOtp,
  verify,
  login,
  socialRegister,
  socialLogin,
  forgotPassword,
  verifyResetOtp,
  resetPassword,
};
