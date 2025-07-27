const express = require('express');
const containerController = require('../controllers/containerController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Public route for MSMEs to view available containers
router.get('/available', containerController.getAvailableContainers);

// Protected routes (requires authentication and role-based access)
router.use(authMiddleware.protect); // All routes below this are protected

router.post('/', authMiddleware.restrictTo('lsp'), containerController.createContainer);
router.get('/', authMiddleware.restrictTo('lsp'), containerController.getLSPContainers);
router.patch('/:id', authMiddleware.restrictTo('lsp'), containerController.updateContainerSpace);

module.exports = router;