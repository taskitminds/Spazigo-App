// Filename: spazigo-backend/controllers/paymentController.js
const razorpay = require('../utils/razorpay');
const pgPool = require('../utils/db');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const crypto = require('crypto'); // For webhook signature verification

exports.createRazorpayOrder = catchAsync(async (req, res, next) => {
  const { bookingId, amount } = req.body; // amount should be in paise (smallest unit)

  if (!bookingId || !amount || isNaN(amount) || amount <= 0) {
    return next(new AppError('Booking ID and a valid amount are required.', 400));
  }

  // Fetch booking details to ensure it's valid and amount is correct
  const bookingResult = await pgPool.query(
    'SELECT b.id, b.status, b.payment_status, c.price, b.weight FROM bookings b JOIN containers c ON b.container_id = c.id WHERE b.id = $1 AND b.msme_id = $2',
    [bookingId, req.user.id]
  );

  if (bookingResult.rows.length === 0) {
    return next(new AppError('Booking not found or you are not authorized for this booking.', 404));
  }

  const booking = bookingResult.rows[0];

  if (booking.status !== 'accepted' || booking.payment_status !== 'pending') {
    return next(new AppError('Booking is not accepted or payment already processed.', 400));
  }

  // Calculate actual amount based on container price and booking weight
  const calculatedAmount = booking.price * booking.weight * 100; // Convert to paise

  if (calculatedAmount !== amount) {
      return next(new AppError('Provided amount does not match calculated booking amount.', 400));
  }


  const options = {
    amount: amount, // amount in the smallest currency unit (e.g., paise for INR)
    currency: 'INR', // Or your currency
    receipt: `receipt_booking_${bookingId}`,
    notes: {
      booking_id: bookingId,
      user_id: req.user.id,
    },
  };

  try {
    const order = await razorpay.orders.create(options);

    // Save Razorpay order ID to booking
    await pgPool.query(
      'UPDATE bookings SET razorpay_order_id = $1 WHERE id = $2',
      [order.id, bookingId]
    );

    res.status(200).json({
      status: 'success',
      data: {
        order_id: order.id,
        currency: order.currency,
        amount: order.amount,
      },
    });
  } catch (error) {
    console.error('Razorpay order creation failed:', error);
    next(new AppError('Failed to create Razorpay order.', 500));
  }
});

exports.razorpayWebhook = catchAsync(async (req, res, next) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET; // Changed to use environment variable
  if (!secret) {
    return next(new AppError('Razorpay webhook secret is not configured.', 500));
  }

  const shasum = crypto.createHmac('sha256', secret);
  shasum.update(JSON.stringify(req.body));
  const digest = shasum.digest('hex');

  if (digest === req.headers['x-razorpay-signature']) {
    const event = req.body.event;
    const payload = req.body.payload;

    if (event === 'payment.captured') {
      const payment = payload.payment;
      const bookingId = payment.notes.booking_id;
      const razorpayPaymentId = payment.id;
      const razorpayOrderId = payment.order_id;
      const paymentStatus = payment.status; // 'captured' for success

      if (bookingId && paymentStatus === 'captured') {
        // Update booking status in your database
        await pgPool.query(
          'UPDATE bookings SET payment_status = $1, razorpay_payment_id = $2, razorpay_order_id = $3, updated_at = NOW() WHERE id = $4',
          ['paid', razorpayPaymentId, razorpayOrderId, bookingId]
        );

        // Optional: Notify LSP that payment is received (fetch LSP's FCM token)
        // Ensure sendPushNotification is imported if uncommented
        // const { sendPushNotification } = require('../utils/firebaseAdmin');
        const bookingInfo = await pgPool.query(
            `SELECT u.fcm_token FROM users u JOIN containers c ON u.id = c.lsp_id JOIN bookings b ON c.id = b.container_id WHERE b.id = $1`,
            [bookingId]
        );
        if (bookingInfo.rows[0] && bookingInfo.rows[0].fcm_token) {
            // Uncomment and ensure sendPushNotification is available if desired
            // await sendPushNotification(
            //   bookingInfo.rows[0].fcm_token,
            //   'Payment Received! 💰',
            //   `Payment confirmed for booking ${bookingId}.`
            // );
        }

        console.log(`Payment captured for booking ${bookingId}. Payment ID: ${razorpayPaymentId}`);
      } else {
        console.warn(`Webhook received for unhandled event or non-captured payment: ${event}`);
      }
    } else if (event === 'payment.failed') {
      const payment = payload.payment;
      const bookingId = payment.notes.booking_id;
      const razorpayPaymentId = payment.id;

      await pgPool.query(
        'UPDATE bookings SET payment_status = $1, razorpay_payment_id = $2, updated_at = NOW() WHERE id = $3',
        ['failed', razorpayPaymentId, bookingId]
      );
      console.log(`Payment failed for booking ${bookingId}. Payment ID: ${razorpayPaymentId}`);
    } else {
        console.log(`Unhandled Razorpay event: ${event}`);
    }

    res.status(200).json({ received: true });
  } else {
    next(new AppError('Invalid Razorpay webhook signature.', 400));
  }
});