const pgPool = require('../utils/db');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { v4: uuidv4 } = require('uuid');

exports.createContainer = catchAsync(async (req, res, next) => {
  const { origin, destination, routes, space_total, price, modal, deadline, departure_time } = req.body;
  const lsp_id = req.user.id; // LSP user ID from JWT

  if (!origin || !destination || !space_total || !price || !modal || !deadline || !departure_time) {
    return next(new AppError('Please provide all required container details.', 400));
  }

  // Basic validation for dates
  if (new Date(deadline) < new Date() || new Date(departure_time) < new Date()) {
    return next(new AppError('Deadline and departure time must be in the future.', 400));
  }

  const id = uuidv4();
  const newContainer = await pgPool.query(
    `INSERT INTO containers (id, lsp_id, origin, destination, routes, space_total, space_left, price, modal, deadline, departure_time, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
    [id, lsp_id, origin, destination, routes || [], space_total, space_total, price, modal, deadline, departure_time, 'active']
  );

  res.status(201).json({
    status: 'success',
    data: {
      container: newContainer.rows[0],
    },
  });
});

exports.getLSPContainers = catchAsync(async (req, res, next) => {
  const lsp_id = req.user.id;
  const containers = await pgPool.query('SELECT * FROM containers WHERE lsp_id = $1 ORDER BY created_at DESC', [lsp_id]);

  res.status(200).json({
    status: 'success',
    results: containers.rows.length,
    data: {
      containers: containers.rows,
    },
  });
});

exports.getAvailableContainers = catchAsync(async (req, res, next) => {
  // Implement location-based filters and dynamic status check
  const { origin, destination, min_price, max_price, modal } = req.query;
  let query = `SELECT c.*, u.company as lsp_company FROM containers c JOIN users u ON c.lsp_id = u.id WHERE c.status = 'active' AND c.space_left > 0 AND c.deadline > NOW()`;
  const queryParams = [];
  let paramIndex = 1;

  if (origin) {
    query += ` AND c.origin ILIKE $${paramIndex++}`;
    queryParams.push(`%${origin}%`);
  }
  if (destination) {
    query += ` AND c.destination ILIKE $${paramIndex++}`;
    queryParams.push(`%${destination}%`);
  }
  if (min_price) {
    query += ` AND c.price >= $${paramIndex++}`;
    queryParams.push(min_price);
  }
  if (max_price) {
    query += ` AND c.price <= $${paramIndex++}`;
    queryParams.push(max_price);
  }
  if (modal) {
    query += ` AND c.modal = $${paramIndex++}`;
    queryParams.push(modal);
  }

  query += ` ORDER BY c.departure_time ASC`;

  const containers = await pgPool.query(query, queryParams);

  res.status(200).json({
    status: 'success',
    results: containers.rows.length,
    data: {
      containers: containers.rows,
    },
  });
});

exports.updateContainerSpace = catchAsync(async (req, res, next) => {
  const { id } = req.params;
  const { space_left } = req.body; // New space_left value

  if (space_left === undefined || isNaN(space_left) || space_left < 0) {
    return next(new AppError('Please provide a valid positive number for space_left.', 400));
  }

  // Ensure LSP is authorized to update *their* container
  const containerCheck = await pgPool.query('SELECT lsp_id, space_total FROM containers WHERE id = $1', [id]);
  if (containerCheck.rows.length === 0) {
    return next(new AppError('Container not found.', 404));
  }
  if (containerCheck.rows[0].lsp_id !== req.user.id) {
    return next(new AppError('You are not authorized to update this container.', 403));
  }
  if (space_left > containerCheck.rows[0].space_total) {
    return next(new AppError('Space left cannot exceed total space.', 400));
  }

  let status = 'active';
  if (space_left === 0) {
    status = 'full';
  }

  const updatedContainer = await pgPool.query(
    'UPDATE containers SET space_left = $1, status = $2, updated_at = NOW() WHERE id = $3 RETURNING *',
    [space_left, status, id]
  );

  res.status(200).json({
    status: 'success',
    data: {
      container: updatedContainer.rows[0],
    },
  });
});

// Automatic container expiry (can be run by a cron job or checked on access)
// For simplicity, we can check status dynamically on fetch or run a periodic background task.
// A more robust solution involves a cron job or scheduled task on your server.
exports.checkAndMarkExpiredContainers = async () => {
  try {
    const expiredContainers = await pgPool.query(
      `UPDATE containers SET status = 'expired', updated_at = NOW() WHERE deadline < NOW() AND status = 'active' RETURNING id`
    );
    if (expiredContainers.rows.length > 0) {
      console.log(`Marked ${expiredContainers.rows.length} containers as expired.`);
    }
  } catch (error) {
    console.error('Error marking expired containers:', error);
  }
};

// Example of running this periodically (e.g., every hour)
// This should ideally be a separate process or handled by a task scheduler like cron/node-schedule
// setInterval(exports.checkAndMarkExpiredContainers, 3600 * 1000); // Run every hour
