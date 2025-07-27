const jwt = require('jsonwebtoken');
const AppError = require('./appError');

const signToken = (id, role) => {
  if (!process.env.JWT_SECRET || !process.env.JWT_EXPIRES_IN) {
    throw new AppError('JWT_SECRET or JWT_EXPIRES_IN not defined in .env', 500);
  }
  return jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

const verifyToken = (token) => {
  if (!process.env.JWT_SECRET) {
    throw new AppError('JWT_SECRET not defined in .env', 500);
  }
  return jwt.verify(token, process.env.JWT_SECRET);
};

module.exports = { signToken, verifyToken };