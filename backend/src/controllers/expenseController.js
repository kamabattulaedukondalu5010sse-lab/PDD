const Expense = require('../models/Expense');
const { getIsConnected } = require('../config/db');
const { mockExpenses } = require('../config/mockDb');

const generateId = () => Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);

// @desc    Add a new expense to a trip
// @route   POST /api/expenses
exports.addExpense = async (req, res) => {
  try {
    const { tripId, title, amount, category, date } = req.body;

    if (!tripId || !title || !amount || !category) {
      return res.status(400).json({ message: 'Missing required expense fields' });
    }

    let savedExpense;

    if (getIsConnected()) {
      const newExpense = new Expense({
        tripId,
        title,
        amount,
        category,
        date: date ? new Date(date) : new Date()
      });
      savedExpense = await newExpense.save();
    } else {
      savedExpense = {
        _id: generateId(),
        tripId,
        title,
        amount: Number(amount),
        category,
        date: date ? new Date(date) : new Date()
      };
      mockExpenses.push(savedExpense);
    }

    res.status(201).json(savedExpense);

  } catch (error) {
    console.error('Add Expense Error:', error);
    res.status(500).json({ message: 'Server error saving expense' });
  }
};

// @desc    Get all expenses for a specific trip
// @route   GET /api/expenses/trip/:tripId
exports.getExpensesByTrip = async (req, res) => {
  try {
    const { tripId } = req.params;

    if (getIsConnected()) {
      const expenses = await Expense.find({ tripId }).sort({ date: -1 });
      res.json(expenses);
    } else {
      const expenses = mockExpenses.filter(e => e.tripId === tripId);
      res.json(expenses);
    }
  } catch (error) {
    console.error('Get Expenses Error:', error);
    res.status(500).json({ message: 'Server error retrieving expenses' });
  }
};

// @desc    Get expense analytics / breakdown for charts
// @route   GET /api/expenses/trip/:tripId/stats
exports.getExpenseStats = async (req, res) => {
  try {
    const { tripId } = req.params;

    let expenses = [];
    if (getIsConnected()) {
      expenses = await Expense.find({ tripId });
    } else {
      expenses = mockExpenses.filter(e => e.tripId === tripId);
    }

    // Aggregate category sums
    const categoryBreakdown = {
      transport: 0,
      stay: 0,
      food: 0,
      activities: 0,
      others: 0
    };

    let totalSpent = 0;

    expenses.forEach(e => {
      if (categoryBreakdown[e.category] !== undefined) {
        categoryBreakdown[e.category] += e.amount;
        totalSpent += e.amount;
      } else {
        categoryBreakdown['others'] += e.amount;
        totalSpent += e.amount;
      }
    });

    res.json({
      tripId,
      totalSpent,
      breakdown: categoryBreakdown
    });

  } catch (error) {
    console.error('Get Expense Stats Error:', error);
    res.status(500).json({ message: 'Server error retrieving expense statistics' });
  }
};
