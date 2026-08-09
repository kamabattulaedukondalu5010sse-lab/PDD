const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://kamabattulaedukondalu5010sse_db_user:lZ9O0YgiZvNMBceA@cluster0.pfdffws.mongodb.net/smart-travel-planner?appName=Cluster0';

async function inspect() {
  console.log('Connecting to database...');
  await mongoose.connect(MONGO_URI);
  console.log('Connected!');

  const Trip = mongoose.model('Trip', new mongoose.Schema({}, { strict: false }));
  const Booking = mongoose.model('Booking', new mongoose.Schema({}, { strict: false }));

  const trips = await Trip.find({});
  console.log(`\nFound ${trips.length} Trips:`);
  trips.forEach(t => {
    console.log(`Trip ID: ${t._id}, Title: ${t.title}, StartDate: ${t.startDate}, EndDate: ${t.endDate}`);
  });

  const bookings = await Booking.find({});
  console.log(`\nFound ${bookings.length} Bookings:`);
  bookings.forEach(b => {
    console.log(`Booking ID: ${b._id}, TripID: ${b.tripId}, Type: ${b.type}, Name: ${b.name}, Cost: ${b.cost}`);
  });

  await mongoose.disconnect();
}

inspect().catch(console.error);
