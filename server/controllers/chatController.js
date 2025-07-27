const pgPool = require('../utils/db');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { v4: uuidv4 } = require('uuid');

// Note: For real-time chat, Socket.io is highly recommended.
// These endpoints would serve as a fall-back or initial message send/history retrieval.

exports.sendMessage = catchAsync(async (req, res, next) => {
  const { receiver_id, container_id, message } = req.body;
  const sender_id = req.user.id;

  if (!receiver_id || !message) {
    return next(new AppError('Receiver ID and message content are required.', 400));
  }

  // Ensure receiver exists
  const receiverExists = await pgPool.query('SELECT id FROM users WHERE id = $1', [receiver_id]);
  if (receiverExists.rows.length === 0) {
    return next(new AppError('Receiver not found.', 404));
  }

  // Optional: Check if container_id is valid if chat is container-specific
  if (container_id) {
    const containerExists = await pgPool.query('SELECT id FROM containers WHERE id = $1', [container_id]);
    if (containerExists.rows.length === 0) {
      return next(new AppError('Container not found for this chat.', 404));
    }
  }

  const id = uuidv4();
  const newMessage = await pgPool.query(
    `INSERT INTO messages (id, sender_id, receiver_id, container_id, message, timestamp)
     VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING *`,
    [id, sender_id, receiver_id, container_id || null, message]
  );

  // If using Socket.io, emit the message here:
  // io.to(receiver_socket_id).emit('newMessage', newMessage.rows[0]);

  res.status(201).json({
    status: 'success',
    data: {
      message: newMessage.rows[0],
    },
  });
});

exports.getConversations = catchAsync(async (req, res, next) => {
  const userId = req.user.id;

  // Get all unique users this user has chatted with
  const conversations = await pgPool.query(
    `SELECT
        CASE
            WHEN sender_id = $1 THEN receiver_id
            ELSE sender_id
        END AS other_user_id,
        MAX(timestamp) as last_message_time,
        container_id
     FROM messages
     WHERE sender_id = $1 OR receiver_id = $1
     GROUP BY other_user_id, container_id
     ORDER BY last_message_time DESC`,
    [userId]
  );

  // For each conversation, fetch the last message and other user's info
  const detailedConversations = await Promise.all(conversations.rows.map(async (conv) => {
    const otherUser = await pgPool.query('SELECT id, email, company, role FROM users WHERE id = $1', [conv.other_user_id]);
    const lastMessage = await pgPool.query(
      `SELECT * FROM messages
       WHERE ((sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1))
       AND (container_id IS NULL OR container_id = $3) -- handle container-specific chats
       ORDER BY timestamp DESC LIMIT 1`,
      [userId, conv.other_user_id, conv.container_id]
    );

    return {
      other_user: otherUser.rows[0],
      container_id: conv.container_id,
      last_message: lastMessage.rows[0],
    };
  }));


  res.status(200).json({
    status: 'success',
    results: detailedConversations.length,
    data: {
      conversations: detailedConversations,
    },
  });
});

exports.getMessagesWithUser = catchAsync(async (req, res, next) => {
  const { otherUserId } = req.params;
  const { container_id } = req.query; // Optional: filter by container if chat is context-specific
  const userId = req.user.id;

  let query = `
    SELECT m.*, s.email AS sender_email, r.email AS receiver_email
    FROM messages m
    JOIN users s ON m.sender_id = s.id
    JOIN users r ON m.receiver_id = r.id
    WHERE ((m.sender_id = $1 AND m.receiver_id = $2) OR (m.sender_id = $2 AND m.receiver_id = $1))
  `;
  const queryParams = [userId, otherUserId];
  let paramIndex = 3;

  if (container_id) {
    query += ` AND m.container_id = $${paramIndex++}`;
    queryParams.push(container_id);
  }

  query += ` ORDER BY m.timestamp ASC`;

  const messages = await pgPool.query(query, queryParams);

  res.status(200).json({
    status: 'success',
    results: messages.rows.length,
    data: {
      messages: messages.rows,
    },
  });
});
