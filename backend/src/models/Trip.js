const mongoose = require('mongoose');

const ItineraryActivitySchema = new mongoose.Schema({
  time: String,
  title: String,
  description: String,
  cost: Number,
  category: {
    type: String,
    enum: ['transport', 'stay', 'food', 'activities', 'others'],
    default: 'activities'
  },
  lat: {
    type: Number,
    default: 0.0
  },
  lng: {
    type: Number,
    default: 0.0
  }
});

const TripSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true
  },
  destination: {
    type: String,
    required: true
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  travelersCount: {
    type: Number,
    default: 1
  },
  budget: {
    type: Number,
    required: true
  },
  optimizedCost: {
    type: Number,
    required: true
  },
  transportType: {
    type: String,
    enum: ['Train', 'Bus', 'Flight'],
    default: 'Train'
  },
  hotelName: {
    type: String,
    default: ''
  },
  itinerary: {
    type: Map,
    of: [ItineraryActivitySchema], // Map of "Day 1", "Day 2", etc. to list of activities
    default: {}
  },
  status: {
    type: String,
    enum: ['upcoming', 'completed'],
    default: 'upcoming'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Trip', TripSchema);
