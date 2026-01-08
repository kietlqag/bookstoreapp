const bcrypt = require('bcryptjs');
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

async function changePassword(userId, currentPassword, newPassword) {
  // Validate input
  if (!currentPassword || !newPassword) {
    const error = new Error('Current password and new password are required.');
    error.status = 400;
    throw error;
  }

  if (newPassword.length < 6) {
    const error = new Error('New password must be at least 6 characters long.');
    error.status = 400;
    throw error;
  }

  // Find user
  const user = await userRepository.findById(userId);
  if (!user) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }

  // Check if user has email (required for password change)
  if (!user.email || user.email.trim() === '') {
    const error = new Error('Vui lòng cập nhật email trước khi đổi mật khẩu.');
    error.status = 400;
    error.code = 'EMAIL_REQUIRED';
    throw error;
  }

  // Check if user has a password (social login users might not have passwordHash)
  if (!user.passwordHash) {
    const error = new Error('Password change not available for this account type.');
    error.status = 400;
    throw error;
  }

  // Verify current password
  const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
  if (!isCurrentPasswordValid) {
    const error = new Error('Current password is incorrect.');
    error.status = 401;
    throw error;
  }

  // Check if new password is different from current password
  const isSamePassword = await bcrypt.compare(newPassword, user.passwordHash);
  if (isSamePassword) {
    const error = new Error('New password must be different from current password.');
    error.status = 400;
    throw error;
  }

  // Hash new password
  const newPasswordHash = await bcrypt.hash(newPassword, 10);

  // Update password
  const updated = await userRepository.updatePasswordById({
    id: userId,
    passwordHash: newPasswordHash,
  });

  if (!updated) {
    const error = new Error('Failed to update password.');
    error.status = 500;
    throw error;
  }

  return { ok: true, message: 'Password changed successfully.' };
}

async function requestAccountDeletion(userId) {
  const user = await userRepository.findById(userId);
  if (!user) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }

  // Check if user has email
  if (!user.email || user.email.trim() === '') {
    const error = new Error('Vui lòng cập nhật email trước khi xóa tài khoản.');
    error.status = 400;
    error.code = 'EMAIL_REQUIRED';
    throw error;
  }

  const email = user.email.trim().toLowerCase();
  const code = generateOtpCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  await userContactOtpRepository.createOtp({
    userId,
    type: 'account_deletion',
    value: email,
    code,
    expiresAt,
  });

  await sendOtpEmail({ to: email, code });

  return {
    message: 'OTP sent to your email.',
  };
}

async function verifyAccountDeletion(userId, code) {
  const user = await userRepository.findById(userId);
  if (!user) {
    const error = new Error('User not found.');
    error.status = 404;
    throw error;
  }

  if (!user.email || user.email.trim() === '') {
    const error = new Error('Email not found.');
    error.status = 400;
    throw error;
  }

  const email = user.email.trim().toLowerCase();
  const otp = await userContactOtpRepository.findLatestOtp({
    userId,
    type: 'account_deletion',
    value: email,
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

  // Mark OTP as verified
  await userContactOtpRepository.markVerified(otp.id);

  // Delete user account (copy to DeletedUser and delete from User)
  const deleted = await userRepository.deleteUser(userId);
  if (!deleted) {
    const error = new Error('Failed to delete account.');
    error.status = 500;
    throw error;
  }

  return {
    ok: true,
    message: 'Tài khoản đã được xóa.',
  };
}

module.exports = {
  getUserProfile,
  getUserSummary,
  updateUserProfile,
  requestEmailChange,
  verifyEmailChange,
  requestPhoneChange,
  verifyPhoneChange,
  changePassword,
  requestAccountDeletion,
  verifyAccountDeletion,
};
