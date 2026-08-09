const mongoose = require('mongoose');

let isConnected = false;

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/smart-travel-planner';
    console.log(`Connecting to MongoDB at: ${mongoURI}`);
    
    // Set a short timeout for connection testing
    await mongoose.connect(mongoURI, {
      serverSelectionTimeoutMS: 5000
    });
    
    isConnected = true;
    console.log('MongoDB Connected Successfully!');
  } catch (error) {
    console.error('MongoDB Connection Failed:', error.message);
    console.log('--- WARNING: RUNNING SERVER WITH IN-MEMORY MOCK FALLBACK DB ---');
    isConnected = false;
  }
};

const getIsConnected = () => isConnected;

module.exports = { connectDB, getIsConnected };
