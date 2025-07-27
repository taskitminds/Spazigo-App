const pgPool = require('../utils/db');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { v4: uuidv4 } = require('uuid');
const { sendPushNotification } = require('../utils/firebaseAdmin');

// You'd also need a middleware for image uploads (e.g., product images for booking)
// exports.uploadBookingImage = upload.single('product_image'); // Assuming you have multer configured

exports.requestBooking = catchAsync(async (req, res, next) => {
  const { container_id, product_name, category, weight } = req.body;
  const msme_id = req.user.id;
  // For simplicity, assuming image_url is provided in body, but ideally it would be an upload process
  const image_url = req.body.image_url || null; // Or use uploadMiddleware.js for a file upload

  if (!container_id || !product_name || !category || !weight) {
    return next(new AppError('Please provide all required booking details.', 400));
  }

  // Check container existence and space
  const containerResult = await pgPool.query('SELECT lsp_id, space_left FROM containers WHERE id = $1 AND status = $2 AND deadline > NOW()', [container_id, 'active']);
  if (containerResult.rows.length === 0) {
    return next(new AppError('Container not found, not active, or booking deadline passed.', 404));
  }
  if (containerResult.rows[0].space_left < weight) { // Assuming weight is the unit for space
    return next(new AppError('Not enough space available in this container.', 400));
  }

  const lsp_id = containerResult.rows[0].lsp_id;

  const id = uuidv4();
  const newBooking = await pgPool.query(
    `INSERT INTO bookings (id, container_id, msme_id, product_name, category, weight, image_url, status, payment_status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
    [id, container_id, msme_id, product_name, category, weight, image_url, 'pending', 'pending']
  );

  // Notify LSP about new booking request
  const lspUser = await pgPool.query('SELECT fcm_token FROM users WHERE id = $1', [lsp_id]);
  if (lspUser.rows[0] && lspUser.rows[0].fcm_token) {
    await sendPushNotification(
      lspUser.rows[0].fcm_token,
      'New Booking Request! 📦',
      `You have a new booking request for container ${container_id} from ${req.user.company}.`
    );
  }

  res.status(201).json({
    status: 'success',
    data: {
      booking: newBooking.rows[0],
    },
  });
});

exports.getMSMEBookings = catchAsync(async (req, res, next) => {
  const msme_id = req.user.id;
  const bookings = await pgPool.query(
    'SELECT b.*, c.origin, c.destination, c.departure_time, c.price FROM bookings b JOIN containers c ON b.container_id = c.id WHERE b.msme_id = $1 ORDER BY b.created_at DESC',
    [msme_id]
  );
  res.status(200).json({
    status: 'success',
    results: bookings.rows.length,
    data: {
      bookings: bookings.rows,
    },
  });
});

exports.getLSPBookingRequests = catchAsync(async (req, res, next) => {
  const lsp_id = req.user.id;
  const bookings = await pgPool.query(
    `SELECT b.*, u.email as msme_email, u.company as msme_company, c.origin, c.destination, c.departure_time
     FROM bookings b
     JOIN containers c ON b.container_id = c.id
     JOIN users u ON b.msme_id = u.id
     WHERE c.lsp_id = $1 ORDER BY b.created_at DESC`,
    [lsp_id]
  );
  res.status(200).json({
    status: 'success',
    results: bookings.rows.length,
    data: {
      bookings: bookings.rows,
    },
  });
});

exports.acceptBooking = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const lsp_id = req.user.id;

  const client = await pgPool.connect();
  try {
    await client.query('BEGIN');

    // Check if booking exists and belongs to LSP's container
    const bookingCheck = await client.query(
      `SELECT b.msme_id, b.container_id, b.weight, b.status, u_msme.fcm_token as msme_fcm_token, c.lsp_id
       FROM bookings b
       JOIN containers c ON b.container_id = c.id
       JOIN users u_msme ON b.msme_id = u_msme.id
       WHERE b.id = $1 AND c.lsp_id = $2`,
      [id, lsp_id]
    );

    if (bookingCheck.rows.length === 0) {
      return next(new AppError('Booking not found or you are not authorized to accept it.', 404));
    }
    if (bookingCheck.rows[0].status !== 'pending') {
      return next(new AppError('Booking is not in pending status and cannot be accepted.', 400));
    }

    // Update booking status
    const updatedBooking = await client.query(
      'UPDATE bookings SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      ['accepted', id]
    );

    // Decrease container space_left
    await client.query(
      'UPDATE containers SET space_left = space_left - $1, updated_at = NOW() WHERE id = $2',
      [bookingCheck.rows[0].weight, bookingCheck.rows[0].container_id]
    );

    await client.query('COMMIT');

    // Send FCM notification to MSME
    if (bookingCheck.rows[0].msme_fcm_token) {
      await sendPushNotification(
        bookingCheck.rows[0].msme_fcm_token,
        'Booking Accepted! ✅',
        `Your booking #${id.substring(0, 8)} for container ${bookingCheck.rows[0].container_id.substring(0, 8)} has been accepted by the LSP.`
      );
    }

    res.status(200).json({
      status: 'success',
      message: 'Booking accepted successfully.',
      data: {
        booking: updatedBooking.rows[0],
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    next(error);
  } finally {
    client.release();
  }
});

exports.rejectBooking = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const { reason } = req.body;
  const lsp_id = req.user.id;

  if (!reason) {
    return next(new AppError('Rejection reason is required.', 400));
  }

  const client = await pgPool.connect();
  try {
    await client.query('BEGIN');

    const bookingCheck = await client.query(
      `SELECT b.msme_id, b.status, u_msme.fcm_token as msme_fcm_token, c.lsp_id, b.container_id
       FROM bookings b
       JOIN containers c ON b.container_id = c.id
       JOIN users u_msme ON b.msme_id = u_msme.id
       WHERE b.id = $1 AND c.lsp_id = $2`,
      [id, lsp_id]
    );

    if (bookingCheck.rows.length === 0) {
      return next(new AppError('Booking not found or you are not authorized to reject it.', 404));
    }
    if (bookingCheck.rows[0].status !== 'pending') {
      return next(new AppError('Booking is not in pending status and cannot be rejected.', 400));
    }

    const updatedBooking = await client.query(
      'UPDATE bookings SET status = $1, rejection_reason = $2, updated_at = NOW() WHERE id = $3 RETURNING *',
      ['rejected', reason, id]
    );

    await client.query('COMMIT');

    // Send FCM notification to MSME
    if (bookingCheck.rows[0].msme_fcm_token) {
      await sendPushNotification(
        bookingCheck.rows[0].msme_fcm_token,
        'Booking Rejected 😔',
        `Your booking #${id.substring(0, 8)} for container ${bookingCheck.rows[0].container_id.substring(0, 8)} was rejected. Reason: ${reason}.`
      );
    }

    res.status(200).json({
      status: 'success',
      message: 'Booking rejected successfully.',
      data: {
        booking: updatedBooking.rows[0],
      },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    next(error);
  } finally {
    client.release();
  }
});

exports.confirmPayment = catchAsync(async (req, res, next) => {
  const { id } = req.params; // Booking ID
  const msme_id = req.user.id;

  // In a real flow, this would be called *after* Razorpay webhook confirms payment
  // This endpoint would primarily update the booking status based on an assumed successful payment.
  // It's crucial to rely on the webhook for payment confirmation, not client-side calls.

  const bookingResult = await pgPool.query(
    'SELECT * FROM bookings WHERE id = $1 AND msme_id = $2',
    [id, msme_id]
  );

  if (bookingResult.rows.length === 0) {
    return next(new AppError('Booking not found or you are not authorized to confirm payment for it.', 404));
  }

  const booking = bookingResult.rows[0];

  if (booking.status !== 'accepted') {
    return next(new AppError('Booking must be accepted before payment can be confirmed.', 400));
  }
  if (booking.payment_status === 'paid') {
    return next(new AppError('Payment for this booking has already been confirmed.', 400));
  }

  const updatedBooking = await pgPool.query(
    'UPDATE bookings SET payment_status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
    ['paid', id]
  );

  // Potentially notify LSP that payment is confirmed
  const lspInfo = await pgPool.query('SELECT u.fcm_token FROM users u JOIN containers c ON u.id = c.lsp_id WHERE c.id = $1', [booking.container_id]);
  if (lspInfo.rows[0] && lspInfo.rows[0].fcm_token) {
    await sendPushNotification(
      lspInfo.rows[0].fcm_token,
      'Payment Confirmed! 💰',
      `Payment confirmed for booking #${id.substring(0, 8)} on your container ${booking.container_id.substring(0, 8)}.`
    );
  }

  res.status(200).json({
    status: 'success',
    message: 'Payment confirmed successfully.',
    data: {
      booking: updatedBooking.rows[0],
    },
  });
});
