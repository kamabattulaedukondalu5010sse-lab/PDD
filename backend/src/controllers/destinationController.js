const Destination = require('../models/Destination');
const { getIsConnected } = require('../config/db');
const { mockDestinations } = require('../config/mockDb');

// @desc    Get all destinations or search destinations
// @route   GET /api/destinations
exports.getDestinations = async (req, res) => {
  try {
    const search = req.query.search || '';

    if (getIsConnected()) {
      let query = {};
      if (search) {
        query = { name: { $regex: search, $options: 'i' } };
      }
      const destinations = await Destination.find(query);
      res.json(destinations);
    } else {
      // Mock Fallback
      if (search) {
        const filtered = mockDestinations.filter(d => d.name.toLowerCase().includes(search.toLowerCase()));
        return res.json(filtered);
      }
      res.json(mockDestinations);
    }
  } catch (error) {
    console.error('Get Destinations Error:', error);
    res.status(500).json({ message: 'Server error retrieving destinations.' });
  }
};

// Seed destinations function for server setup
exports.seedDestinations = async () => {
  if (!getIsConnected()) return;

  try {
    const count = await Destination.countDocuments();
    if (count === 0) {
      await Destination.insertMany(mockDestinations.map(({ _id, ...rest }) => rest));
      console.log('Pre-populated destinations seeded in MongoDB!');
    }
  } catch (error) {
    console.error('Failed to seed destinations:', error.message);
  }
};
