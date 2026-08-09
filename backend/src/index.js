const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { connectDB } = require('./config/db');
const { seedDestinations } = require('./controllers/destinationController');

// Load environment variables
dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/trips', require('./routes/tripRoutes'));
app.use('/api/bookings', require('./routes/bookingRoutes'));
app.use('/api/expenses', require('./routes/expenseRoutes'));
app.use('/api/destinations', require('./routes/destinationRoutes'));

// Welcome route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to the Smart Travel Planner API!' });
});

// Port configuration
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  // Try connecting to MongoDB
  await connectDB();
  
  // Seed Destinations if connected to Mongo
  await seedDestinations();
  
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
};

startServer();
