const { Router } = require('express');
const userController = require('../controllers/user.controller');

const router = Router();

router.get('/:id/summary', userController.getUserSummary);
router.get('/:id', userController.getUser);
router.put('/:id', userController.updateUser);
router.post('/:id/email/request', userController.requestEmailChange);
router.post('/:id/email/verify', userController.verifyEmailChange);
router.post('/:id/phone/request', userController.requestPhoneChange);
router.post('/:id/phone/verify', userController.verifyPhoneChange);

module.exports = router;
