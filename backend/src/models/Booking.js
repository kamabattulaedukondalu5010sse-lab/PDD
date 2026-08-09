const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  tripId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
    required: true
  },
  type: {
    type: String,
    enum: ['hotel', 'transport'],
    required: true
  },
  name: {
    type: String,
    required: true // Name of Hotel or Train/Bus/Flight number
  },
  details: {
    type: String, // e.g. "Deluxe Room" or "Konkan Express (2AC)"
    default: ''
  },
  cost: {
    type: Number,
    required: true
  },
  bookingIdString: {
    type: String,
    required: true // Custom ID string e.g. "TRP123456789"
  },
  status: {
    type: String,
    enum: ['pending', 'confirmed'],
    default: 'confirmed'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Booking', BookingSchema);
