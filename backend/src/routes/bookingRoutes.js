const express = require('express');
const router = express.Router();
const { createBooking, getBookingsByTrip, getUserBookings } = require('../controllers/bookingController');
const protect = require('../middleware/auth');

router.use(protect);

router.post('/', createBooking);
router.get('/', getUserBookings);
router.get('/trip/:tripId', getBookingsByTrip);

module.exports = router;
