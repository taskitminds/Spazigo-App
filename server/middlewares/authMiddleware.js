const { promisify } = require('util');
const AppError = require('../utils/appError');
const catchAsync = require('../utils/catchAsync');
const pgPool = require('../utils/db');
const { verifyToken } = require('../utils/jwt');

exports.protect = catchAsync(async (req, res, next) => {
  // 1) Get token and check if it's there
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  } else if (req.cookies && req.cookies.jwt) { // For cookie-based JWT (optional)
    token = req.cookies.jwt;
  }

  if (!token) {
    return next(new AppError('You are not logged in! Please log in to get access.', 401));
  }

  // 2) Verify token
  let decoded;
  try {
    decoded = await promisify(verifyToken)(token);
  } catch (err) {
    if (err.name === 'JsonWebTokenError') {
      return next(new AppError('Invalid token. Please log in again!', 401));
    }
    if (err.name === 'TokenExpiredError') {
      return next(new AppError('Your token has expired! Please log in again.', 401));
    }
    return next(new AppError('Authentication failed.', 401));
  }


  // 3) Check if user still exists
  const userResult = await pgPool.query('SELECT id, role, email, status, company, phone, fcm_token FROM users WHERE id = $1', [decoded.id]);

  if (userResult.rows.length === 0) {
    return next(new AppError('The user belonging to this token no longer exists.', 401));
  }

  // 4) Check if user is verified (admin approval)
  if (userResult.rows[0].status !== 'verified' && userResult.rows[0].role !== 'admin') { // Admin doesn't need to be verified by another admin
    return next(new AppError('Your account is not yet verified by an administrator. Please wait for approval.', 403));
  }

  // GRANT ACCESS TO PROTECTED ROUTE
  req.user = userResult.rows[0];
  next();
});

exports.restrictTo = (...roles) => {
  return (req, res, next) => {
    // roles is an array like ['admin', 'lsp']
    if (!roles.includes(req.user.role)) {
      return next(new AppError('You do not have permission to perform this action', 403));
    }
    next();
  };
};