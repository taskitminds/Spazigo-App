const jwt = require('jsonwebtoken');
const AppError = require('./appError');

exports.signToken = (id, role) => {
  if (!process.env.JWT_SECRET || !process.env.JWT_EXPIRES_IN) {
    // This is a server configuration error, should not happen in production
    throw new AppError('JWT secret or expiration not defined.', 500);
  }
  return jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

// No need for a separate verifyToken export as we use promisify(jwt.verify) directly
// in the middleware for cleaner async/await syntax.