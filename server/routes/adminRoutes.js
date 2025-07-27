const express = require('express');
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(authMiddleware.protect, authMiddleware.restrictTo('admin')); // All admin routes require admin role

router.get('/pending-users', adminController.getPendingUsers);
router.patch('/verify/:userId', adminController.verifyUser);
router.patch('/reject/:userId', adminController.rejectUser);

module.exports = router;