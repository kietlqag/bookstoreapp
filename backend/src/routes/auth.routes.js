const { Router } = require('express');
const authController = require('../controllers/auth.controller');

const router = Router();

router.post('/register', authController.register);
router.post('/resend', authController.resend);
router.post('/verify', authController.verify);
router.post('/login', authController.login);
router.post('/social/register', authController.socialRegister);
router.post('/social/login', authController.socialLogin);
router.post('/logout', authController.logout);
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-reset-otp', authController.verifyResetOtp);
router.post('/reset-password', authController.resetPassword);

module.exports = router;
