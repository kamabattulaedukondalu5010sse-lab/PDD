const Booking = require('../models/Booking');
const { getIsConnected } = require('../config/db');
const { mockBookings } = require('../config/mockDb');

const generateId = () => Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);

// @desc    Create a new booking (Hotel/Transport)
// @route   POST /api/bookings
exports.createBooking = async (req, res) => {
  try {
    const { tripId, type, name, details, cost } = req.body;
    const userId = req.user.id;

    if (!tripId || !type || !name || !cost) {
      return res.status(400).json({ message: 'Missing required booking information' });
    }

    const bookingIdString = 'TRP' + Math.floor(100000000 + Math.random() * 900000000);

    let savedBooking;

    if (getIsConnected()) {
      const newBooking = new Booking({
        userId,
        tripId,
        type,
        name,
        details,
        cost,
        bookingIdString,
        status: 'confirmed'
      });
      savedBooking = await newBooking.save();
    } else {
      savedBooking = {
        _id: generateId(),
        userId,
        tripId,
        type,
        name,
        details,
        cost,
        bookingIdString,
        status: 'confirmed',
        createdAt: new Date()
      };
      mockBookings.push(savedBooking);
    }

    res.status(201).json(savedBooking);

  } catch (error) {
    console.error('Create Booking Error:', error);
    res.status(500).json({ message: 'Server error placing booking' });
  }
};

// @desc    Get all bookings for a specific trip
// @route   GET /api/bookings/trip/:tripId
exports.getBookingsByTrip = async (req, res) => {
  try {
    const { tripId } = req.params;

    if (getIsConnected()) {
      const bookings = await Booking.find({ tripId });
      res.json(bookings);
    } else {
      const bookings = mockBookings.filter(b => b.tripId === tripId);
      res.json(bookings);
    }
  } catch (error) {
    console.error('Get Trip Bookings Error:', error);
    res.status(500).json({ message: 'Server error retrieving bookings' });
  }
};

// @desc    Get all bookings for the logged-in user
// @route   GET /api/bookings
exports.getUserBookings = async (req, res) => {
  try {
    const userId = req.user.id;

    if (getIsConnected()) {
      const bookings = await Booking.find({ userId }).sort({ createdAt: -1 });
      res.json(bookings);
    } else {
      const bookings = mockBookings.filter(b => b.userId === userId);
      res.json(bookings);
    }
  } catch (error) {
    console.error('Get User Bookings Error:', error);
    res.status(500).json({ message: 'Server error retrieving user bookings' });
  }
};
