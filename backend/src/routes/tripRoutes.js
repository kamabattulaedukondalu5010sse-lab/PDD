const express = require('express');
const router = express.Router();
const { createTrip, getTrips, getTripById, deleteTrip, updateTripStatus } = require('../controllers/tripController');
const protect = require('../middleware/auth');

router.use(protect);

router.post('/', createTrip);
router.get('/', getTrips);
router.get('/:id', getTripById);
router.delete('/:id', deleteTrip);
router.put('/:id/status', updateTripStatus);

module.exports = router;
