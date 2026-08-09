const mongoose = require('mongoose');

const DestinationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true
  },
  description: {
    type: String,
    required: true
  },
  imageUrl: {
    type: String,
    required: true
  },
  rating: {
    type: Number,
    default: 4.5
  },
  costFactor: {
    type: Number,
    default: 1.0 // Base pricing multiplier (e.g. Goa = 1.0, Manali = 1.2, Kerala = 1.1, Dubai = 2.5)
  },
  category: {
    type: String,
    default: 'Beach' // Beach, Mountain, Heritage, Adventure
  },
  lat: {
    type: Number,
    required: true,
    default: 0.0
  },
  lng: {
    type: Number,
    required: true,
    default: 0.0
  }
});

module.exports = mongoose.model('Destination', DestinationSchema);
