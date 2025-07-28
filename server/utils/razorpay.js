const Razorpay = require('razorpay');

let instance;

// Check for keys and initialize Razorpay client only once
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
  instance = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });
} else {
  console.error('CRITICAL: Razorpay API keys are not defined in the .env file. Payment routes will fail.');
  // Create a mock instance to prevent crashing the app on startup
  // Any calls to this mock will fail gracefully in the controller.
  instance = {
    orders: {
      create: () => Promise.reject(new Error('Razorpay is not configured.')),
    },
  };
}

module.exports = instance;