const express = require('express');
const chatController = require('../controllers/chatController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(authMiddleware.protect); // All chat routes require authentication

router.post('/', chatController.sendMessage);
router.get('/conversations', chatController.getConversations); // Get all conversations for a user
router.get('/:otherUserId', chatController.getMessagesWithUser); // Get messages with a specific user

module.exports = router;