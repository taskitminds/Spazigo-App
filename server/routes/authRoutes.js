const express = require('express');
const authController = require('../controllers/authController');
const { uploadSingleDocument } = require('../middlewares/uploadMiddleware');


const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/admin-login', authController.adminLogin);

module.exports = router;