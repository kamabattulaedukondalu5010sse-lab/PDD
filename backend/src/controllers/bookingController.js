const Booking = require('../models/Booking');
const { getIsConnected } = require('../config/db');
const { mockBookings, mockTrips } = require('../config/mockDb');

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

    // 1. Retrieve the trip details to compare dates
    let currentTrip;
    if (getIsConnected()) {
      const Trip = require('../models/Trip');
      currentTrip = await Trip.findById(tripId);
    } else {
      currentTrip = mockTrips.find(t => t._id === tripId);
    }

    if (!currentTrip) {
      return res.status(404).json({ message: 'Trip details not found' });
    }

    // 2. Check if the user already has a booking of this type for this trip
    let existingBookingForTrip;
    if (getIsConnected()) {
      existingBookingForTrip = await Booking.findOne({ tripId, type });
    } else {
      existingBookingForTrip = mockBookings.find(b => b.tripId === tripId && b.type === type);
    }

    if (existingBookingForTrip) {
      return res.status(400).json({ message: `You have already confirmed a ${type} reservation for this trip.` });
    }

    // 3. Check for overlapping dates in existing bookings of the same type
    let userBookings;
    if (getIsConnected()) {
      userBookings = await Booking.find({ userId });
    } else {
      userBookings = mockBookings.filter(b => b.userId === userId);
    }

    if (getIsConnected()) {
      const Trip = require('../models/Trip');
      for (const b of userBookings) {
        if (b.type === type) {
          const bookedTrip = await Trip.findById(b.tripId);
          if (bookedTrip) {
            const overlap = (new Date(currentTrip.startDate) <= new Date(bookedTrip.endDate)) && 
                            (new Date(currentTrip.endDate) >= new Date(bookedTrip.startDate));
            if (overlap) {
              return res.status(400).json({ 
                message: `Booking conflict: You already have a ${type} reservation (${b.name}) for an overlapping trip (${bookedTrip.title}) during this date period.` 
              });
            }
          }
        }
      }
    } else {
      for (const b of userBookings) {
        if (b.type === type) {
          const bookedTrip = mockTrips.find(t => t._id === b.tripId);
          if (bookedTrip) {
            const overlap = (new Date(currentTrip.startDate) <= new Date(bookedTrip.endDate)) && 
                            (new Date(currentTrip.endDate) >= new Date(bookedTrip.startDate));
            if (overlap) {
              return res.status(400).json({ 
                message: `Booking conflict: You already have a ${type} reservation (${b.name}) for an overlapping trip (${bookedTrip.title}) during this date period.` 
              });
            }
          }
        }
      }
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
