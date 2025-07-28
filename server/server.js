const express = require('express');
const dotenv = require('dotenv');
const morgan = require('morgan');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const xss = require('xss-clean');
const hpp = require('hpp');
const mongoSanitize = require('express-mongo-sanitize');

dotenv.config({ path: './server/.env' });

const pgPool = require('./utils/db');
const connectMongoDB = require('./utils/mongoDb');
const { createPgTables } = require('./utils/dbSetup');
const { initFirebaseAdmin } = require('./utils/firebaseAdmin');
const AppError = require('./utils/appError');
const globalErrorHandler = require('./controllers/errorController');

const authRoutes = require('./routes/authRoutes');
const containerRoutes = require('./routes/containerRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const adminRoutes = require('./routes/adminRoutes');
const chatRoutes = require('./routes/chatRoutes');

const app = express();

// --- Database & Services Initialization ---
(async () => {
    try {
        await pgPool.connect();
        console.log('PostgreSQL connected successfully!');
        await createPgTables();
        connectMongoDB();
        initFirebaseAdmin();
    } catch (err) {
        console.error('Initialization failed:', err);
        process.exit(1);
    }
})();


// --- Global Middlewares ---

// Set security HTTP headers
app.use(helmet());

// Enable CORS for all routes
app.use(cors());
app.options('*', cors()); // Enable pre-flight for all routes

// Development logging
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
}

// Limit requests from same API to prevent brute-force attacks
const limiter = rateLimit({
    max: 200, // Allow more requests per window
    windowMs: 15 * 60 * 1000, // 15 minutes
    message: 'Too many requests from this IP, please try again in 15 minutes!'
});
app.use('/api', limiter);

// Body parser, reading data from body into req.body. Increased limit for base64 uploads.
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));


// Data sanitization
app.use(mongoSanitize()); // Against NoSQL query injection
app.use(xss()); // Against XSS attacks

// Prevent parameter pollution
app.use(hpp({
    whitelist: [] // Add whitelisted parameters here if needed
}));


// --- API Routes ---
app.use('/api/auth', authRoutes);
app.use('/api/containers', containerRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/chat', chatRoutes);

// --- Health Check Route ---
app.get('/', (req, res) => {
    res.status(200).json({ status: 'success', message: 'Spazigo API is running.' });
});


// --- Error Handling ---
app.all('*', (req, res, next) => {
    next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

app.use(globalErrorHandler);


// --- Start Server ---
const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

// Graceful shutdown
process.on('unhandledRejection', err => {
    console.error('UNHANDLED REJECTION! 💥 Shutting down...', err);
    server.close(() => {
        process.exit(1);
    });
});

process.on('SIGTERM', () => {
    console.log('👋 SIGTERM RECEIVED. Shutting down gracefully.');
    server.close(() => {
        console.log('Process terminated!');
    });
});