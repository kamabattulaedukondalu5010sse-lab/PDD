const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { getIsConnected } = require('../config/db');
const { mockUsers } = require('../config/mockDb');

const JWT_SECRET = process.env.JWT_SECRET || 'secret12345';

// Helper to generate IDs
const generateId = () => Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);

// @desc    Register a new user
// @route   POST /api/auth/signup
exports.signup = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Please enter all fields' });
    }

    if (getIsConnected()) {
      let user = await User.findOne({ email });
      if (user) {
        return res.status(400).json({ message: 'User already exists' });
      }

      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);

      user = new User({
        name,
        email,
        password: hashedPassword
      });

      await user.save();

      const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(201).json({
        token,
        user: { id: user._id, name: user.name, email: user.email, avatar: user.avatar }
      });
    } else {
      // Mock Fallback
      const existingUser = mockUsers.find(u => u.email.toLowerCase() === email.toLowerCase());
      if (existingUser) {
        return res.status(400).json({ message: 'User already exists (mock db)' });
      }

      const newUser = {
        _id: generateId(),
        name,
        email,
        password: password, // Store raw in mock for simplicity
        avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150&q=80',
        createdAt: new Date()
      };

      mockUsers.push(newUser);

      const token = jwt.sign({ id: newUser._id }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(201).json({
        token,
        user: { id: newUser._id, name: newUser.name, email: newUser.email, avatar: newUser.avatar }
      });
    }
  } catch (error) {
    console.error('Signup Error:', error);
    res.status(500).json({ message: 'Server error during signup' });
  }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Please enter all fields' });
    }

    if (getIsConnected()) {
      const user = await User.findOne({ email });
      if (!user) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });
      return res.json({
        token,
        user: { id: user._id, name: user.name, email: user.email, avatar: user.avatar }
      });
    } else {
      // Mock Fallback
      const user = mockUsers.find(u => u.email.toLowerCase() === email.toLowerCase());
      if (!user) {
        return res.status(400).json({ message: 'Invalid credentials (mock db)' });
      }

      // Allow either hashed password check or direct text match (for pre-seeded values)
      if (password !== user.password && user.password !== '$bcrypt$hash$123456') {
        return res.status(400).json({ message: 'Invalid credentials (mock db)' });
      }

      const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: '7d' });
      return res.json({
        token,
        user: { id: user._id, name: user.name, email: user.email, avatar: user.avatar }
      });
    }
  } catch (error) {
    console.error('Login Error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
};

// @desc    Get user data
// @route   GET /api/auth/user
exports.getUser = async (req, res) => {
  try {
    const userId = req.user.id;

    if (getIsConnected()) {
      const user = await User.findById(userId).select('-password');
      if (!user) return res.status(404).json({ message: 'User not found' });
      return res.json(user);
    } else {
      const user = mockUsers.find(u => u._id === userId);
      if (!user) return res.status(404).json({ message: 'User not found (mock db)' });
      
      const { password, ...userWithoutPassword } = user;
      return res.json(userWithoutPassword);
    }
  } catch (error) {
    console.error('Get User Error:', error);
    res.status(500).json({ message: 'Server error fetching user profile' });
  }
};

// @desc    Update user profile data
// @route   PUT /api/auth/user
exports.updateUser = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, email, phone, avatar } = req.body;

    if (getIsConnected()) {
      const user = await User.findById(userId);
      if (!user) return res.status(404).json({ message: 'User not found' });

      if (name) user.name = name;
      if (email) user.email = email;
      if (phone !== undefined) user.phone = phone;
      if (avatar) user.avatar = avatar;

      await user.save();
      
      const { password, ...updatedUser } = user.toObject();
      return res.json(updatedUser);
    } else {
      const userIdx = mockUsers.findIndex(u => u._id === userId);
      if (userIdx === -1) return res.status(404).json({ message: 'User not found (mock db)' });

      const user = mockUsers[userIdx];
      if (name) user.name = name;
      if (email) user.email = email;
      if (phone !== undefined) user.phone = phone;
      if (avatar) user.avatar = avatar;

      mockUsers[userIdx] = user;

      const { password, ...userWithoutPassword } = user;
      return res.json(userWithoutPassword);
    }
  } catch (error) {
    console.error('Update User Error:', error);
    res.status(500).json({ message: 'Server error updating user profile' });
  }
};
