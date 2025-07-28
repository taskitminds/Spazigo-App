const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const morgan = require('morgan');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const xss = require('xss-clean');
const hpp = require('hpp');
const mongoSanitize = require('express-mongo-sanitize');

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, './.env') });

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
app.use(helmet());
app.use(cors());
app.options('*', cors());

if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
}

const limiter = rateLimit({
    max: 200,
    windowMs: 15 * 60 * 1000,
    message: 'Too many requests from this IP, please try again in 15 minutes!'
});
app.use('/api', limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

app.use(mongoSanitize());
app.use(xss());
app.use(hpp({ whitelist: [] }));


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