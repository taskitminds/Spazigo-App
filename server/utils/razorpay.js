const Razorpay = require('razorpay');
const AppError = require('./appError'); // Assuming AppError for better error messages

// Ensure keys are loaded from .env
if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
  console.error('Razorpay API keys are not defined in .env');
  // In a real app, you might want to exit or throw an error here during startup
  // throw new AppError('Razorpay API keys are missing', 500);
}

const instance = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

module.exports = instance;