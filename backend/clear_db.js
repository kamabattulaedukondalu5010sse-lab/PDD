const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb+srv://kamabattulaedukondalu5010sse_db_user:lZ9O0YgiZvNMBceA@cluster0.pfdffws.mongodb.net/smart-travel-planner?appName=Cluster0';

async function clear() {
  console.log('Connecting to database to clear old trips/bookings...');
  await mongoose.connect(MONGO_URI);
  console.log('Connected!');

  const Trip = mongoose.model('Trip', new mongoose.Schema({}, { strict: false }));
  const Booking = mongoose.model('Booking', new mongoose.Schema({}, { strict: false }));

  const tripsResult = await Trip.deleteMany({});
  console.log(`Deleted ${tripsResult.deletedCount} old trips.`);

  const bookingsResult = await Booking.deleteMany({});
  console.log(`Deleted ${bookingsResult.deletedCount} old bookings.`);

  await mongoose.disconnect();
  console.log('Done clearing database.');
}

clear().catch(console.error);
