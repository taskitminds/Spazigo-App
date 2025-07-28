const pgPool = require('../utils/db');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { sendPushNotification } = require('../utils/firebaseAdmin');
const Document = require('../models/mongo/documentModel'); // To fetch documents

exports.getPendingUsers = catchAsync(async (req, res, next) => {
  const usersResult = await pgPool.query(
    'SELECT id, email, role, company, phone, status, created_at FROM users WHERE status = $1',
    ['pending']
  );

  // Optionally fetch documents for each user
  const pendingUsers = usersResult.rows;
  for (let user of pendingUsers) {
    const documents = await Document.find({ user_id: user.id });
    user.documents = documents.map(doc => ({
      document_type: doc.document_type,
      file_name: doc.file_name,
      mimetype: doc.mimetype,
      file_path: doc.file_path, // Base64 or URL
      uploaded_at: doc.uploaded_at
    }));
  }

  res.status(200).json({
    status: 'success',
    results: pendingUsers.length,
    data: {
      users: pendingUsers,
    },
  });
});

exports.verifyUser = catchAsync(async (req, res, next) => {
  const { userId } = req.params;

  const userResult = await pgPool.query(
    'UPDATE users SET status = $1 WHERE id = $2 RETURNING id, email, fcm_token',
    ['verified', userId]
  );

  if (userResult.rows.length === 0) {
    return next(new AppError('User not found or already verified/rejected.', 404));
  }

  const verifiedUser = userResult.rows[0];

  // Send FCM notification
  if (verifiedUser.fcm_token) {
    await sendPushNotification(
      verifiedUser.fcm_token,
      'Account Approved! 🎉',
      'Great news! Your Spazigo account has been approved by the administrator. You can now log in and start using the app.'
    );
  }

  res.status(200).json({
    status: 'success',
    message: 'User successfully verified and notified.',
    data: {
      user: {
        id: verifiedUser.id,
        email: verifiedUser.email,
        status: 'verified'
      }
    },
  });
});

exports.rejectUser = catchAsync(async (req, res, next) => {
  const { userId } = req.params;
  const { reason } = req.body;

  if (!reason) {
    return next(new AppError('Rejection reason is required.', 400));
  }

  const userResult = await pgPool.query(
    'UPDATE users SET status = $1, rejection_reason = $2 WHERE id = $3 RETURNING id, email, fcm_token',
    ['rejected', reason, userId]
  );

  if (userResult.rows.length === 0) {
    return next(new AppError('User not found or already verified/rejected.', 404));
  }

  const rejectedUser = userResult.rows[0];

  // Send FCM notification
  if (rejectedUser.fcm_token) {
    await sendPushNotification(
      rejectedUser.fcm_token,
      'Account Update: Verification Rejected 😔',
      `Unfortunately, your Spazigo account verification was rejected. Reason: ${reason}. Please contact support for more details.`
    );
  }

  res.status(200).json({
    status: 'success',
    message: 'User successfully rejected and notified.',
    data: {
      user: {
        id: rejectedUser.id,
        email: rejectedUser.email,
        status: 'rejected',
        rejection_reason: reason
      }
    },
  });
});