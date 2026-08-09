const express = require('express');
const router = express.Router();
const { addExpense, getExpensesByTrip, getExpenseStats } = require('../controllers/expenseController');
const protect = require('../middleware/auth');

router.use(protect);

router.post('/', addExpense);
router.get('/trip/:tripId', getExpensesByTrip);
router.get('/trip/:tripId/stats', getExpenseStats);

module.exports = router;
