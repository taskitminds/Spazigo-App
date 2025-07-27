const express = require('express');
const paymentController = require('../controllers/paymentController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Webhook route - often doesn't require JWT, Razorpay sends its own signature
router.post('/webhook', paymentController.razorpayWebhook);

router.use(authMiddleware.protect); // All routes below this are protected

router.post('/create-order', authMiddleware.restrictTo('msme'), paymentController.createRazorpayOrder);

module.exports = router;