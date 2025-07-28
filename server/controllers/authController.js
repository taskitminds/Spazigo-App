const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const pgPool = require('../utils/db');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { signToken } = require('../utils/jwt');
const Document = require('../models/mongo/documentModel');

const createSendToken = (user, statusCode, res) => {
    const token = signToken(user.id, user.role);
    user.password = undefined;

    res.status(statusCode).json({
        status: 'success',
        token,
        data: {
            user,
        },
    });
};

exports.register = catchAsync(async (req, res, next) => {
    const {
        email,
        password,
        role,
        company,
        phone,
        base64Document,
        documentFileName,
        documentMimeType,
        fcm_token
    } = req.body;

    if (!email || !password || !role || !company || !phone || !base64Document || !documentFileName || !documentMimeType) {
        return next(new AppError('Please provide all required fields including a document.', 400));
    }

    if (!['lsp', 'msme'].includes(role)) {
        return next(new AppError('Role must be either "lsp" or "msme".', 400));
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const id = uuidv4();

    const client = await pgPool.connect();
    try {
        await client.query('BEGIN');

        const newUserResult = await client.query(
            'INSERT INTO users (id, role, email, password, company, phone, status, fcm_token) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id, role, email, status, company, phone, fcm_token, created_at',
            [id, role, email, hashedPassword, company, phone, 'pending', fcm_token || null]
        );
        const newUser = newUserResult.rows[0];

        const newDocument = new Document({
            user_id: newUser.id,
            document_type: 'registration_document',
            file_name: documentFileName,
            mimetype: documentMimeType,
            file_path: base64Document,
        });
        await newDocument.save();

        await client.query('COMMIT');

        // Do NOT send token on registration, user needs to wait for approval
        res.status(201).json({
            status: 'success',
            message: 'Registration successful. Your account is pending admin approval.',
            data: {
                user: newUser,
            },
        });
    } catch (err) {
        await client.query('ROLLBACK');
        if (err.code === '23505') {
            return next(new AppError('User with this email already exists.', 409));
        }
        // Log the actual error for debugging
        console.error('REGISTRATION ERROR:', err);
        return next(new AppError('Failed to register user. Please try again later.', 500));
    } finally {
        client.release();
    }
});


exports.login = catchAsync(async (req, res, next) => {
    const { email, password, fcm_token } = req.body;

    if (!email || !password) {
        return next(new AppError('Please provide email and password.', 400));
    }

    const userResult = await pgPool.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = userResult.rows[0];

    if (!user || !(await bcrypt.compare(password, user.password))) {
        return next(new AppError('Incorrect email or password.', 401));
    }
    
    // For pending or rejected users, provide a specific status in the response
    if (user.status !== 'verified') {
        return res.status(403).json({
            status: 'fail',
            message: `Your account is currently ${user.status}. Please wait for admin approval or contact support.`,
            data: {
                status: user.status,
                rejection_reason: user.rejection_reason
            }
        });
    }

    if (fcm_token && user.fcm_token !== fcm_token) {
        await pgPool.query('UPDATE users SET fcm_token = $1 WHERE id = $2', [fcm_token, user.id]);
        user.fcm_token = fcm_token;
    }

    createSendToken(user, 200, res);
});


exports.adminLogin = catchAsync(async (req, res, next) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return next(new AppError('Please provide admin email and password.', 400));
    }
    
    if (email !== process.env.ADMIN_EMAIL || password !== process.env.ADMIN_PASSWORD) {
        return next(new AppError('Incorrect email or password.', 401));
    }

    const adminUser = {
        id: 'admin_user', // Static ID for admin user
        email: process.env.ADMIN_EMAIL,
        role: 'admin',
        status: 'verified',
        company: 'Spazigo Admin',
        phone: 'N/A',
        created_at: new Date().toISOString()
    };

    createSendToken(adminUser, 200, res);
});