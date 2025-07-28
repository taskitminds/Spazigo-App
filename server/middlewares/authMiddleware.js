const { promisify } = require('util');
const jwt = require('jsonwebtoken');
const AppError = require('../utils/appError');
const catchAsync = require('../utils/catchAsync');
const pgPool = require('../utils/db');

exports.protect = catchAsync(async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return next(new AppError('You are not logged in. Please log in to get access.', 401));
  }

  const decoded = await promisify(jwt.verify)(token, process.env.JWT_SECRET);

  const currentUserResult = await pgPool.query('SELECT * FROM users WHERE id = $1', [decoded.id]);
  const currentUser = currentUserResult.rows[0];

  if (!currentUser) {
    return next(new AppError('The user belonging to this token no longer exists.', 401));
  }
  
  // Attach user to the request object
  req.user = currentUser;
  next();
});

exports.restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(new AppError('You do not have permission to perform this action.', 403));
    }
    next();
  };
};