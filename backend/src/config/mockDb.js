// In-memory fallback database when MongoDB is offline
const mockUsers = [
  {
    _id: '60d000000000000000000001',
    name: 'John Doe',
    email: 'john@example.com',
    password: '$bcrypt$hash$123456', // Simulated hash
    avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150&q=80',
    phone: '+91 98765 43210',
    createdAt: new Date()
  }
];

const mockDestinations = [
  {
    _id: '60d000000000000000000101',
    name: 'Goa',
    description: 'Beach Paradise with scenic views, palm trees, and vibrant nightlife.',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80',
    rating: 4.8,
    costFactor: 1.0,
    category: 'Beach',
    lat: 15.2993,
    lng: 74.1240
  },
  {
    _id: '60d000000000000000000102',
    name: 'Manali',
    description: 'Snow Mountains, adventure sports, and scenic valley drives.',
    imageUrl: 'https://images.unsplash.com/photo-1596701062351-dfc21a4d80a5?auto=format&fit=crop&w=500&q=80',
    rating: 4.7,
    costFactor: 1.2,
    category: 'Mountain',
    lat: 32.2396,
    lng: 77.1887
  },
  {
    _id: '60d000000000000000000103',
    name: 'Kerala',
    description: 'God\'s Own Country with serene backwaters, houseboats, and greenery.',
    imageUrl: 'https://images.unsplash.com/photo-1602216056096-3c40cc0c9944?auto=format&fit=crop&w=500&q=80',
    rating: 4.6,
    costFactor: 1.1,
    category: 'Nature',
    lat: 10.8505,
    lng: 76.2711
  },
  {
    _id: '60d000000000000000000104',
    name: 'Dubai',
    description: 'Luxury & Adventure, tallest buildings, deserts, and shopping malls.',
    imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=500&q=80',
    rating: 4.9,
    costFactor: 2.5,
    category: 'Luxury',
    lat: 25.2048,
    lng: 55.2708
  },
  {
    _id: '60d000000000000000000105',
    name: 'Shimla',
    description: 'Beautiful hill station, heritage train, and colonial architecture.',
    imageUrl: 'https://images.unsplash.com/photo-1597075687490-8f673c6c17f6?auto=format&fit=crop&w=500&q=80',
    rating: 4.5,
    costFactor: 1.1,
    category: 'Mountain',
    lat: 31.1048,
    lng: 77.1734
  },
  {
    _id: '60d000000000000000000106',
    name: 'Jaipur',
    description: 'The Pink City, magnificent palaces, forts, and rich heritage.',
    imageUrl: 'https://images.unsplash.com/photo-1477584305590-38772bfc1937?auto=format&fit=crop&w=500&q=80',
    rating: 4.7,
    costFactor: 1.15,
    category: 'Heritage',
    lat: 26.9124,
    lng: 75.7873
  },
  {
    _id: '60d000000000000000000107',
    name: 'Leh Ladakh',
    description: 'Stunning high-altitude desert, lakes, monasteries, and adventure.',
    imageUrl: 'https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=500&q=80',
    rating: 4.9,
    costFactor: 1.5,
    category: 'Adventure',
    lat: 34.1526,
    lng: 77.5770
  }
];

const mockTrips = [
  {
    _id: '60d000000000000000000201',
    userId: '60d000000000000000000001',
    title: 'Goa Trip',
    destination: 'Goa',
    startDate: new Date('2026-05-20'),
    endDate: new Date('2026-05-25'),
    travelersCount: 2,
    budget: 25000,
    optimizedCost: 20099,
    transportType: 'Train',
    hotelName: 'Beach Resort Goa',
    status: 'upcoming',
    itinerary: {
      'Day 1': [
        { time: '09:00 AM', title: 'Arrive in Goa', description: 'Arrive at Madgaon Station, take cab to hotel.', cost: 1200, category: 'transport', lat: 15.2736, lng: 73.9582 },
        { time: '12:00 PM', title: 'Check-in at Hotel', description: 'Check-in at Beach Resort Goa and rest.', cost: 0, category: 'stay', lat: 15.5494, lng: 73.7535 },
        { time: '04:00 PM', title: 'Calangute Beach', description: 'Relax at the beach side and enjoy sunset.', cost: 500, category: 'activities', lat: 15.5442, lng: 73.7550 },
        { time: '08:00 PM', title: 'Dinner at Beach Shack', description: 'Have local Goan curry at the shack.', cost: 1200, category: 'food', lat: 15.5550, lng: 73.7520 }
      ],
      'Day 2': [
        { time: '10:00 AM', title: 'Scuba Diving at Grand Island', description: 'Undersea exploration and underwater photoshoot.', cost: 2500, category: 'activities', lat: 15.4294, lng: 73.7742 },
        { time: '02:00 PM', title: 'Lunch at German Bakery', description: 'Enjoy fresh continental dishes.', cost: 800, category: 'food', lat: 15.5994, lng: 73.7480 },
        { time: '06:00 PM', title: 'Fort Aguada', description: 'Explore Portuguese lighthouse and historical fort.', cost: 100, category: 'activities', lat: 15.4926, lng: 73.7736 }
      ]
    },
    createdAt: new Date()
  }
];

const mockBookings = [];

const mockExpenses = [
  {
    _id: '60d000000000000000000401',
    tripId: '60d000000000000000000201',
    title: 'Beach Resort Goa (Stay)',
    amount: 9000,
    category: 'stay',
    date: new Date('2026-05-20')
  },
  {
    _id: '60d000000000000000000402',
    tripId: '60d000000000000000000201',
    title: 'Konkan Express Tickets',
    amount: 7500,
    category: 'transport',
    date: new Date('2026-05-20')
  },
  {
    _id: '60d000000000000000000403',
    tripId: '60d000000000000000000201',
    title: 'Dinner at Beach Shack',
    amount: 3000,
    category: 'food',
    date: new Date('2026-05-21')
  },
  {
    _id: '60d000000000000000000404',
    tripId: '60d000000000000000000201',
    title: 'Scuba Diving Activity',
    amount: 1750,
    category: 'activities',
    date: new Date('2026-05-21')
  }
];

module.exports = {
  mockUsers,
  mockDestinations,
  mockTrips,
  mockBookings,
  mockExpenses
};
