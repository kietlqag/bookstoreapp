const userRepository = require('../repositories/user.repository');
const userContactOtpRepository = require('../repositories/user_contact_otp.repository');
const { sendOtpEmail } = require('../config/mailer');
const { sendSmsOtp } = require('../config/sms');

async function getUserProfile(id) {
  const user = await userRepository.findPublicById(id);
  if (!user) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }
  return user;
}

async function getUserSummary(id) {
  const user = await userRepository.findPublicById(id);
  if (!user) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }
  const stats = await userRepository.findProfileStats(id);
  return {
    ...user,
    orderCount: Number(stats?.orderCount || 0),
    pendingCount: Number(stats?.pendingCount || 0),
    waitingPickupCount: Number(stats?.waitingPickupCount || 0),
    shippingCount: Number(stats?.shippingCount || 0),
    deliveredCount: Number(stats?.deliveredCount || 0),
    reviewPendingCount: Number(stats?.reviewPendingCount || 0),
    cancelledCount: Number(stats?.cancelledCount || 0),
    bookCount: Number(stats?.bookCount || 0),
    favoriteCount: Number(stats?.favoriteCount || 0),
    totalSpend: Number(stats?.totalSpend || 0),
    monthlySpend: Number(stats?.monthlySpend || 0),
  };
}

async function updateUserProfile(id, payload) {
  const user = await userRepository.findById(id);
  if (!user) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }

  const fullName = payload.fullName?.toString().trim();
  const address = payload.address?.toString().trim();
  const avatar = payload.avatar?.toString() ?? user.avatar ?? '';

  return userRepository.updateProfile({
    id,
    fullName: fullName || user.fullName,
    email: user.email,
    phoneNumber: user.phoneNumber,
    address: address ?? user.address,
    avatar,
  });
}

function generateOtpCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

async function requestEmailChange(userId, email) {
  const normalized = email.trim().toLowerCase();
  const user = await userRepository.findById(userId);
  if (user && (user.email || '').toLowerCase() === normalized) {
    const error = new Error('Thông tin mới phải khác hiện tại');
    error.status = 400;
    throw error;
  }
  if (!normalized) {
    const error = new Error('Email is required.');
    error.status = 400;
    throw error;
  }
  const existing = await userRepository.findByEmail(normalized);
  if (existing && existing.id !== userId) {
    const error = new Error('Email already exists.');
    error.status = 409;
    throw error;
  }
  const code = generateOtpCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
  await userContactOtpRepository.createOtp({
    userId,
    type: 'email',
    value: normalized,
    code,
    expiresAt,
  });
  await sendOtpEmail({ to: normalized, code });
  return {
    message: 'OTP sent.',
  };
}

async function verifyEmailChange(userId, email, code) {
  const normalized = email.trim().toLowerCase();
  const otp = await userContactOtpRepository.findLatestOtp({
    userId,
    type: 'email',
    value: normalized,
  });
  if (!otp || otp.verifiedAt) {
    const error = new Error('OTP not found.');
    error.status = 400;
    throw error;
  }
  if (otp.code !== code) {
    const error = new Error('Invalid OTP.');
    error.status = 400;
    throw error;
  }
  if (new Date(otp.expiresAt).getTime() < Date.now()) {
    const error = new Error('OTP expired.');
    error.status = 400;
    throw error;
  }
  await userContactOtpRepository.markVerified(otp.id);
  const user = await userRepository.findById(userId);
  return userRepository.updateProfile({
    id: userId,
    fullName: user?.fullName,
    email: normalized,
    phoneNumber: user?.phoneNumber,
    address: user?.address,
    avatar: user?.avatar,
  });
}

async function requestPhoneChange(userId, phoneNumber) {
  const normalized = phoneNumber.trim();
  const user = await userRepository.findById(userId);
  if (user && (user.phoneNumber || '') === normalized) {
    const error = new Error('Thông tin mới phải khác hiện tại');
    error.status = 400;
    throw error;
  }
  if (!normalized) {
    const error = new Error('Phone number is required.');
    error.status = 400;
    throw error;
  }
  const existing = await userRepository.findByPhone(normalized);
  const code = generateOtpCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
  await userContactOtpRepository.createOtp({
    userId,
    type: 'phone',
    value: normalized,
    code,
    expiresAt,
  });
  await sendSmsOtp({ phone: normalized, code });
  return {
    message: 'OTP sent.',
  };
}

async function verifyPhoneChange(userId, phoneNumber, code) {
  const normalized = phoneNumber.trim();
  const otp = await userContactOtpRepository.findLatestOtp({
    userId,
    type: 'phone',
    value: normalized,
  });
  if (!otp || otp.verifiedAt) {
    const error = new Error('OTP not found.');
    error.status = 400;
    throw error;
  }
  if (otp.code !== code) {
    const error = new Error('Invalid OTP.');
    error.status = 400;
    throw error;
  }
  if (new Date(otp.expiresAt).getTime() < Date.now()) {
    const error = new Error('OTP expired.');
    error.status = 400;
    throw error;
  }
  await userContactOtpRepository.markVerified(otp.id);
  const user = await userRepository.findById(userId);
  return userRepository.updateProfile({
    id: userId,
    fullName: user?.fullName,
    email: user?.email,
    phoneNumber: normalized,
    address: user?.address,
    avatar: user?.avatar,
  });
}

module.exports = {
  getUserProfile,
  getUserSummary,
  updateUserProfile,
  requestEmailChange,
  verifyEmailChange,
  requestPhoneChange,
  verifyPhoneChange,
};
