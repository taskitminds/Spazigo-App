const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const pgPool = require('../utils/db');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { signToken } = require('../utils/jwt');
const Document = require('../models/mongo/documentModel'); // MongoDB model
const { uploadSingleDocument } = require('../middlewares/uploadMiddleware'); // Import the multer middleware

const createSendToken = (user, statusCode, res) => {
  const token = signToken(user.id, user.role); // Include role in token
  // Remove sensitive data from output
  user.password = undefined;

  res.status(statusCode).json({
    status: 'success',
    token,
    data: {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        company: user.company,
        phone: user.phone,
        status: user.status,
        fcm_token: user.fcm_token // Include FCM token if present
      },
    },
  });
};

exports.register = catchAsync(async (req, res, next) => {
  // Use uploadSingleDocument middleware
  uploadSingleDocument(req, res, async (err) => {
    if (err) {
      return next(err); // Pass Multer errors to global error handler
    }

    const { email, password, role, company, phone } = req.body;
    const fcm_token = req.body.fcm_token || null; // Optional FCM token during registration

    if (!email || !password || !role || !company || !phone) {
      return next(new AppError('Please provide email, password, role, company, and phone number.', 400));
    }

    if (!['lsp', 'msme'].includes(role)) {
      return next(new AppError('Role must be either "lsp" or "msme".', 400));
    }

    if (!req.file) {
      return next(new AppError('Please upload a legal document (image or PDF).', 400));
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const id = uuidv4(); // Generate UUID for PostgreSQL

    const client = await pgPool.connect();
    try {
      await client.query('BEGIN'); // Start transaction

      const newUserResult = await client.query(
        'INSERT INTO users (id, role, email, password, company, phone, status, fcm_token) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id, role, email, status, company, phone, fcm_token',
        [id, role, email, hashedPassword, company, phone, 'pending', fcm_token]
      );
      const newUser = newUserResult.rows[0];

      // Save document to MongoDB (storing base64 for now, consider cloud storage for production)
      const document = new Document({
        user_id: newUser.id,
        document_type: 'registration_document', // Or determine dynamically
        file_name: req.file.originalname,
        mimetype: req.file.mimetype,
        file_path: req.file.buffer.toString('base64'), // Storing file content as base64
        // For production, upload `req.file.buffer` to S3/GCS and store the URL here.
      });
      await document.save();

      await client.query('COMMIT'); // Commit transaction

      res.status(201).json({
        status: 'success',
        message: 'Registration successful. Your account is pending admin approval.',
        data: {
          user: newUser,
        },
      });
    } catch (err) {
      await client.query('ROLLBACK'); // Rollback transaction on error
      if (err.code === '23505') { // PostgreSQL unique violation error code
        return next(new AppError('User with that email already exists.', 409));
      }
      next(new AppError('Failed to register user.', 500));
    } finally {
      client.release(); // Release client back to pool
    }
  });
});

exports.login = catchAsync(async (req, res, next) => {
  const { email, password, fcm_token } = req.body;

  // 1) Check if email and password exist
  if (!email || !password) {
    return next(new AppError('Please provide email and password!', 400));
  }

  // 2) Check if user exists and password is correct
  const userResult = await pgPool.query('SELECT * FROM users WHERE email = $1', [email]);
  const user = userResult.rows[0];

  if (!user || !(await bcrypt.compare(password, user.password))) {
    return next(new AppError('Incorrect email or password', 401));
  }

  // 3) Check if user is verified by admin
  if (user.status !== 'verified') {
    return next(new AppError('Your account is not yet verified by an administrator. Please wait for approval.', 403));
  }

  // 4) Update FCM token if provided and different
  if (fcm_token && user.fcm_token !== fcm_token) {
    await pgPool.query('UPDATE users SET fcm_token = $1 WHERE id = $2', [fcm_token, user.id]);
    user.fcm_token = fcm_token; // Update the user object for the response
  }

  // 5) If everything is ok, send token to client
  createSendToken(user, 200, res);
});

// Admin Login (separate endpoint for clarity, direct check against .env)
exports.adminLogin = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;

  if (email !== process.env.ADMIN_EMAIL || password !== process.env.ADMIN_PASSWORD) {
    return next(new AppError('Invalid admin credentials', 401));
  }

  // For a basic setup, we simulate an admin user object for JWT
  const adminUser = {
    id: 'admin_static_id', // A consistent ID for the .env admin
    email: process.env.ADMIN_EMAIL,
    role: 'admin',
    status: 'verified', // Admin is always considered verified
  };

  createSendToken(adminUser, 200, res);
});