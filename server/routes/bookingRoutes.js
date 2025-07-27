const express = require('express');
const bookingController = require('../controllers/bookingController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(authMiddleware.protect); // All routes below this are protected

router.post('/', authMiddleware.restrictTo('msme'), bookingController.requestBooking); // MSME requests booking
router.get('/msme', authMiddleware.restrictTo('msme'), bookingController.getMSMEBookings); // MSME views own bookings
router.get('/lsp', authMiddleware.restrictTo('lsp'), bookingController.getLSPBookingRequests); // LSP views received requests

router.patch('/:id/accept', authMiddleware.restrictTo('lsp'), bookingController.acceptBooking); // LSP accepts
router.patch('/:id/reject', authMiddleware.restrictTo('lsp'), bookingController.rejectBooking); // LSP rejects
router.patch('/:id/pay', authMiddleware.restrictTo('msme'), bookingController.confirmPayment); // MSME confirms payment (after Razorpay success)

module.exports = router;