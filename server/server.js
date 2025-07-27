const express = require('express');
const dotenv = require('dotenv');
const morgan = require('morgan');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const xss = require('xss-clean');
const hpp = require('hpp');
const mongoSanitize = require('express-mongo-sanitize');

// Load environment variables
dotenv.config({ path: './.env' });

// Database Connections
const pgPool = require('./utils/db'); // PostgreSQL
const connectMongoDB = require('./utils/mongoDb'); // MongoDB

// Firebase Admin SDK Initialization
const { initFirebaseAdmin } = require('./utils/firebaseAdmin');

// Error Handling Utilities
const AppError = require('./utils/appError');
const globalErrorHandler = require('./controllers/errorController'); // We'll create this simple one

// Route Imports
const authRoutes = require('./routes/authRoutes');
const containerRoutes = require('./routes/containerRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const adminRoutes = require('./routes/adminRoutes');
const chatRoutes = require('./routes/chatRoutes');

const app = express();

// Initialize Database Connections
pgPool.connect()
  .then(() => console.log('PostgreSQL connected successfully!'))
  .catch(err => console.error('PostgreSQL connection error:', err));

connectMongoDB(); // Connect to MongoDB

initFirebaseAdmin(); // Initialize Firebase Admin SDK

// 1) GLOBAL MIDDLEWARES
// Set security HTTP headers
app.use(helmet());

// Development logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Limit requests from same API to prevent brute-force attacks
const limiter = rateLimit({
  max: 100, // Max 100 requests per hour
  windowMs: 60 * 60 * 1000, // 1 hour
  message: 'Too many requests from this IP, please try again in an hour!'
});
app.use('/api', limiter); // Apply to all API routes

// Body parser, reading data from body into req.body
app.use(express.json({ limit: '10kb' })); // Limit JSON payload size
app.use(express.urlencoded({ extended: true, limit: '10kb' })); // For URL-encoded data

// Data sanitization against NoSQL query injection
app.use(mongoSanitize()); // Prevents malicious MongoDB queries

// Data sanitization against XSS attacks
app.use(xss()); // Cleans user input from malicious HTML/JS code

// Prevent parameter pollution (e.g., ?sort=price&sort=duration)
app.use(hpp({
  whitelist: [
    // Add specific query parameters that are allowed to be duplicated
    // For example, if you allow multiple categories in a filter: 'category'
  ]
}));

// Enable CORS for all routes (adjust for production to specific origins)
app.use(cors());

// Serve static files if needed (e.g., uploaded documents for testing, but not for production)
// app.use(express.static(`${__dirname}/public`));

// 2) ROUTES
app.use('/api/auth', authRoutes);
app.use('/api/containers', containerRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/chat', chatRoutes);

// Handle unhandled routes (404 Not Found)
app.all('*', (req, res, next) => {
  next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

// Global Error Handling Middleware
app.use(globalErrorHandler);

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
});

// Handle unhandled promise rejections (e.g., DB connection errors outside Express)
process.on('unhandledRejection', err => {
  console.log('UNHANDLED REJECTION! 💥 Shutting down...');
  console.error(err.name, err.message, err.stack);
  server.close(() => {
    process.exit(1); // Exit with a failure code
  });
});

// Handle SIGTERM (e.g., Heroku sending SIGTERM to shut down app gracefully)
process.on('SIGTERM', () => {
  console.log('👋 SIGTERM RECEIVED. Shutting down gracefully...');
  server.close(() => {
    console.log('Process terminated!');
  });
});