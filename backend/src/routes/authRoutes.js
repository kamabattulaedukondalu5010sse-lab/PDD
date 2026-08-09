const express = require('express');
const router = express.Router();
const { signup, login, getUser, updateUser } = require('../controllers/authController');
const protect = require('../middleware/auth');

router.post('/signup', signup);
router.post('/login', login);
router.get('/user', protect, getUser);
router.put('/user', protect, updateUser);

module.exports = router;
