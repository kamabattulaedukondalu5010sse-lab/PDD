import React, { useState, useEffect } from 'react';
import { 
  Plane, Calendar, Users, IndianRupee, Compass, Navigation, Hotel, 
  MapPin, CheckCircle, Bell, User, Settings, ArrowRight, TrendingDown,
  DollarSign, PieChart, Landmark, Heart, Eye, LogOut, Check, ChevronRight,
  TrendingUp, Plus, Trash2, Clock, History
} from 'lucide-react';
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js';
import { Doughnut } from 'react-chartjs-2';

ChartJS.register(ArcElement, Tooltip, Legend);

const API_URL = 'https://pdd-4xpy.onrender.com/api';

const destCoordsMap = {
  Goa: [15.2993, 74.1240],
  Manali: [32.2396, 77.1887],
  Kerala: [10.8505, 76.2711],
  Dubai: [25.2048, 55.2708],
  Shimla: [31.1048, 77.1734],
  Jaipur: [26.9124, 75.7873],
  'Leh Ladakh': [34.1526, 77.5770]
};

const enrichActivitiesWithCoords = (destination, activities) => {
  if (!destination || !activities || activities.length === 0) return activities;
  const d = destination.toLowerCase();
  
  const coords = {
    goa: [
      [15.2736, 73.9582], // transport_in
      [15.5494, 73.7535], // hotel
      [15.5442, 73.7550], // explore
      [15.5550, 73.7520], // dinner
      [15.4294, 73.7742], // activity
      [15.5994, 73.7480], // lunch
      [15.4926, 73.7736]  // sightseeing
    ],
    manali: [
      [32.2276, 77.1873],
      [32.2530, 77.1850],
      [32.2450, 77.1860],
      [32.2500, 77.1900],
      [32.2630, 77.1880],
      [32.2520, 77.1840],
      [32.2700, 77.1800]
    ],
    kerala: [
      [9.9816, 76.2999],
      [9.4981, 76.3388],
      [9.5300, 76.3500],
      [9.5100, 76.3400],
      [9.5400, 76.3600],
      [9.5200, 76.3350],
      [9.4900, 76.3200]
    ],
    dubai: [
      [25.2532, 55.3657],
      [25.2285, 55.3273],
      [25.1972, 55.2744],
      [25.2000, 55.2800],
      [25.2100, 55.2600],
      [25.1900, 55.2700],
      [25.1800, 55.2500]
    ],
    shimla: [
      [31.1033, 77.1610],
      [31.1044, 77.1700],
      [31.1050, 77.1740],
      [31.1060, 77.1720],
      [31.1100, 77.1800],
      [31.1020, 77.1680],
      [31.1080, 77.1780]
    ],
    jaipur: [
      [26.9220, 75.7860],
      [26.9150, 75.8000],
      [26.9250, 75.8200],
      [26.9180, 75.8100],
      [26.9855, 75.8513],
      [26.9200, 75.7900],
      [26.9239, 75.8267]
    ],
    leh: [
      [34.1444, 77.5555],
      [34.1600, 77.5800],
      [34.1500, 77.6000],
      [34.1550, 77.5900],
      [34.1700, 77.6200],
      [34.1620, 77.5700],
      [34.1438, 77.5850]
    ]
  };

  const destKey = Object.keys(coords).find(k => d.includes(k)) || 'goa';
  const defaultList = coords[destKey];

  return activities.map((act, idx) => {
    if (act.lat && act.lng) return act;
    const fallback = defaultList[idx % defaultList.length];
    return {
      ...act,
      lat: fallback[0],
      lng: fallback[1]
    };
  });
};

const getAllTripActivities = (trip) => {
  if (!trip || !trip.itinerary) return [];
  const activities = [];
  const sortedDays = Object.keys(trip.itinerary).sort();
  sortedDays.forEach(day => {
    if (Array.isArray(trip.itinerary[day])) {
      activities.push(...trip.itinerary[day]);
    } else if (trip.itinerary.get && typeof trip.itinerary.get === 'function') {
      const dayActivities = trip.itinerary.get(day);
      if (Array.isArray(dayActivities)) {
        activities.push(...dayActivities);
      }
    }
  });
  return activities;
};

function TripMap({ activities, destinationCoords }) {
  const mapRef = React.useRef(null);
  const leafletMapInstance = React.useRef(null);

  React.useEffect(() => {
    let checkLeaflet;
    const initMap = () => {
      if (!window.L || !window.L.Routing || !mapRef.current) return;
      if (leafletMapInstance.current) {
        leafletMapInstance.current.remove();
        leafletMapInstance.current = null;
      }

      const L = window.L;
      let center = destinationCoords || [15.2993, 74.1240];
      const points = [];

      activities.forEach(act => {
        if (act.lat && act.lng) {
          points.push([act.lat, act.lng]);
        }
      });

      if (points.length > 0) {
        center = points[0];
      }

      const map = L.map(mapRef.current).setView(center, 12);
      leafletMapInstance.current = map;

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
      }).addTo(map);

      const customIcon = L.icon({
        iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
        shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
        iconSize: [25, 41],
        iconAnchor: [12, 41],
        popupAnchor: [1, -34]
      });

      if (points.length > 1) {
        L.Routing.control({
          waypoints: points.map(pt => L.latLng(pt[0], pt[1])),
          routeWhileDragging: false,
          addWaypoints: false,
          draggableWaypoints: false,
          fitSelectedRoutes: true,
          show: false,
          createMarker: function(i, waypoint, n) {
            const act = activities.find(a => 
              Math.abs(a.lat - waypoint.latLng.lat) < 0.0001 && 
              Math.abs(a.lng - waypoint.latLng.lng) < 0.0001
            );
            return L.marker(waypoint.latLng, { icon: customIcon })
              .bindPopup(`<b>Step ${i + 1}: ${act ? act.title : 'Activity'}</b><br/>${act ? act.time : ''}<br/>${act ? act.description : ''}`);
          },
          lineOptions: {
            styles: [{ color: '#2563EB', opacity: 0.8, weight: 6 }]
          }
        }).addTo(map);
      } else if (points.length === 1) {
        L.marker(points[0], { icon: customIcon })
          .addTo(map)
          .bindPopup(`<b>${activities[0].title}</b><br/>${activities[0].time}`);
      }
    };

    checkLeaflet = setInterval(() => {
      if (window.L && window.L.Routing) {
        clearInterval(checkLeaflet);
        initMap();
      }
    }, 100);

    return () => {
      clearInterval(checkLeaflet);
      if (leafletMapInstance.current) {
        leafletMapInstance.current.remove();
        leafletMapInstance.current = null;
      }
    };
  }, [activities, destinationCoords]);

  return (
    <div style={{ position: 'relative', width: '100%', height: '350px', borderRadius: '12px', overflow: 'hidden', border: '1px solid #E2E8F0', marginTop: '1rem', zIndex: 1 }}>
      <div ref={mapRef} style={{ width: '100%', height: '100%' }} />
    </div>
  );
}

export default function App() {
  // Authentication State
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [user, setUser] = useState(JSON.parse(localStorage.getItem('user')) || null);
  const [authMode, setAuthMode] = useState('login'); // login or signup
  const [authForm, setAuthForm] = useState({ name: '', email: '', password: '' });
  const [authError, setAuthError] = useState('');

  // App Navigation & Views
  const [currentTab, setCurrentTab] = useState('dashboard'); // dashboard, planner, bookings, expenses, profile, settings
  
  // Data State
  const [destinations, setDestinations] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [trips, setTrips] = useState([]);
  const [currentTrip, setCurrentTrip] = useState(null);
  const [bookings, setBookings] = useState([]);
  const [expenses, setExpenses] = useState([]);
  const [expenseStats, setExpenseStats] = useState(null);

  // Form State
  const [plannerForm, setPlannerForm] = useState({
    destination: 'Goa',
    startDate: '2026-05-20',
    endDate: '2026-05-25',
    travelersCount: 2,
    budget: 25000
  });
  const [optimizationResult, setOptimizationResult] = useState(null);
  const [newExpenseForm, setNewExpenseForm] = useState({
    title: '',
    amount: '',
    category: 'food'
  });

  // Notifications Mock
  const notifications = [
    { id: 1, title: 'Booking Confirmed', text: 'Your stay at Beach Resort Goa is confirmed.', time: '2 hours ago' },
    { id: 2, title: 'Price Drop Alert', text: 'Flight prices dropped for Dubai trip!', time: '1 day ago' },
    { id: 3, title: 'Weather Update', text: 'Goa is sunny and perfect for swimming.', time: '2 days ago' }
  ];

  useEffect(() => {
    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);
    }
    if (!document.getElementById('leaflet-routing-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-routing-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.css';
      document.head.appendChild(link);
    }

    if (!document.getElementById('leaflet-js')) {
      const script = document.createElement('script');
      script.id = 'leaflet-js';
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.onload = () => {
        if (!document.getElementById('leaflet-routing-js')) {
          const rScript = document.createElement('script');
          rScript.id = 'leaflet-routing-js';
          rScript.src = 'https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.js';
          document.head.appendChild(rScript);
        }
      };
      document.head.appendChild(script);
    } else {
      if (!document.getElementById('leaflet-routing-js')) {
        const rScript = document.createElement('script');
        rScript.id = 'leaflet-routing-js';
        rScript.src = 'https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.js';
        document.head.appendChild(rScript);
      }
    }
  }, []);

  // Fetch initial content
  useEffect(() => {
    fetchDestinations();
    if (token) {
      fetchTrips();
      fetchBookings();
    }
  }, [token]);

  // Sync current trip updates
  useEffect(() => {
    if (currentTrip) {
      fetchExpenses(currentTrip._id);
      fetchExpenseStats(currentTrip._id);
    }
  }, [currentTrip, trips]);

  const getHeaders = () => ({
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  });

  const fetchDestinations = async () => {
    try {
      const res = await fetch(`${API_URL}/destinations?search=${searchQuery}`);
      const data = await res.json();
      setDestinations(data);
    } catch (e) {
      // Fallback
      setDestinations([
        { name: 'Goa', description: 'Beach Paradise with scenic views.', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=300&q=80', rating: 4.8, costFactor: 1.0, category: 'Beach' },
        { name: 'Manali', description: 'Snow Mountains and valley drives.', imageUrl: 'https://images.unsplash.com/photo-1626621422476-eb347823b18d?auto=format&fit=crop&w=300&q=80', rating: 4.7, costFactor: 1.2, category: 'Mountain' },
        { name: 'Kerala', description: 'Serene backwaters and greenery.', imageUrl: 'https://images.unsplash.com/photo-1602216056096-3c40cc0c9944?auto=format&fit=crop&w=300&q=80', rating: 4.6, costFactor: 1.1, category: 'Nature' },
        { name: 'Dubai', description: 'Luxury and adventure desert safari.', imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=300&q=80', rating: 4.9, costFactor: 2.5, category: 'Luxury' },
        { name: 'Shimla', description: 'Beautiful hill station and colonial architecture.', imageUrl: 'https://images.unsplash.com/photo-1597075687490-8f673c6c17f6?auto=format&fit=crop&w=300&q=80', rating: 4.5, costFactor: 1.1, category: 'Mountain' },
        { name: 'Jaipur', description: 'Pink City and magnificent palaces.', imageUrl: 'https://images.unsplash.com/photo-1477584305590-38772bfc1937?auto=format&fit=crop&w=300&q=80', rating: 4.7, costFactor: 1.15, category: 'Heritage' },
        { name: 'Leh Ladakh', description: 'Stunning high-altitude desert and lakes.', imageUrl: 'https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=300&q=80', rating: 4.9, costFactor: 1.5, category: 'Adventure' }
      ]);
    }
  };

  const fetchTrips = async () => {
    try {
      const res = await fetch(`${API_URL}/trips`, { headers: getHeaders() });
      if (res.ok) {
        const data = await res.json();
        setTrips(data);
        if (data.length > 0 && !currentTrip) {
          setCurrentTrip(data[0]);
        }
      }
    } catch (e) {
      setTrips([
        {
          _id: 'mock_trip_goa',
          title: 'Goa Trip',
          destination: 'Goa',
          startDate: '2026-05-20',
          endDate: '2026-05-25',
          travelersCount: 2,
          budget: 25000,
          optimizedCost: 20099,
          transportType: 'Train',
          hotelName: 'Beach Resort Goa',
          status: 'upcoming',
          itinerary: {
            'Day 1': [
              { time: '09:00 AM', title: 'Arrive in Goa', description: 'Arrive at Madgaon Station, take cab to hotel.', cost: 1200, category: 'transport' },
              { time: '12:00 PM', title: 'Check-in at Hotel', description: 'Check-in at Beach Resort Goa (Deluxe Room).', cost: 0, category: 'stay' },
              { time: '04:00 PM', title: 'Calangute Beach', description: 'Relax at the beach side.', cost: 500, category: 'activities' }
            ],
            'Day 2': [
              { time: '10:00 AM', title: 'Scuba Diving at Grand Island', description: 'Undersea exploration.', cost: 2500, category: 'activities' }
            ]
          }
        }
      ]);
    }
  };

  const fetchBookings = async () => {
    try {
      const res = await fetch(`${API_URL}/bookings`, { headers: getHeaders() });
      if (res.ok) setBookings(await res.json());
    } catch (e) {
      setBookings([
        { _id: 'b1', type: 'hotel', name: 'Beach Resort Goa', details: 'Deluxe Room', cost: 4999, bookingIdString: 'TRP123456789', status: 'confirmed' },
        { _id: 'b2', type: 'transport', name: 'Konkan Express', details: 'AC 3 Tier (Train)', cost: 2500, bookingIdString: 'TRP987654321', status: 'confirmed' }
      ]);
    }
  };

  const fetchExpenses = async (tripId) => {
    try {
      const res = await fetch(`${API_URL}/expenses/trip/${tripId}`, { headers: getHeaders() });
      if (res.ok) setExpenses(await res.json());
    } catch (e) {
      setExpenses([
        { _id: 'e1', title: 'Beach Resort Goa (Stay)', amount: 9000, category: 'stay' },
        { _id: 'e2', title: 'Konkan Express Train', amount: 7500, category: 'transport' },
        { _id: 'e3', title: 'Scuba Diving Activity', amount: 1750, category: 'activities' }
      ]);
    }
  };

  const fetchExpenseStats = async (tripId) => {
    try {
      const res = await fetch(`${API_URL}/expenses/trip/${tripId}/stats`, { headers: getHeaders() });
      if (res.ok) setExpenseStats(await res.json());
    } catch (e) {
      setExpenseStats({
        totalSpent: 18250,
        breakdown: { transport: 7500, stay: 9000, food: 0, activities: 1750, others: 0 }
      });
    }
  };

  // Actions
  const handleAuthSubmit = async (e) => {
    e.preventDefault();
    setAuthError('');
    const endpoint = authMode === 'login' ? 'login' : 'signup';
    
    try {
      const res = await fetch(`${API_URL}/auth/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(authForm)
      });
      const data = await res.json();
      if (!res.ok) {
        setAuthError(data.message || 'Authentication failed');
        return;
      }
      
      localStorage.setItem('token', data.token);
      localStorage.setItem('user', JSON.stringify(data.user));
      setToken(data.token);
      setUser(data.user);
    } catch (err) {
      // Simulate login for offline mock
      const mockUser = { id: 'mock_user_id', name: authForm.name || 'John Doe', email: authForm.email, avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150&q=80' };
      localStorage.setItem('token', 'mock_token');
      localStorage.setItem('user', JSON.stringify(mockUser));
      setToken('mock_token');
      setUser(mockUser);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken('');
    setUser(null);
    setCurrentTrip(null);
  };

  const runPlannerOptimization = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${API_URL}/trips`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify(plannerForm)
      });
      const data = await res.json();
      if (res.ok) {
        setOptimizationResult(data.optimization);
        fetchTrips();
      }
    } catch (err) {
      // Simulated optimization breakdown for offline mode
      const isGoa = plannerForm.destination.toLowerCase() === 'goa';
      const optCost = isGoa && Number(plannerForm.budget) === 25000 ? 20099 : Math.round(plannerForm.budget * 0.82);
      const savings = isGoa && Number(plannerForm.budget) === 25000 ? 3200 : Math.round(plannerForm.budget * 0.18);
      
      const optResult = {
        standardCost: optCost + savings,
        optimizedCost: optCost,
        savings: savings,
        transportRecommendation: 'Train (Konkan Express) is the most cost-effective and comfortable option.',
        stayRecommendation: 'Choosing a Deluxe Room instead of Beach Sea View suites saves big money.',
        breakdown: {
          transport: Math.round(optCost * 0.40),
          stay: Math.round(optCost * 0.30),
          food: Math.round(optCost * 0.15),
          activities: Math.round(optCost * 0.10),
          others: Math.round(optCost * 0.05)
        }
      };
      setOptimizationResult(optResult);
      
      const newTrip = {
        _id: 'mock_trip_' + Date.now(),
        title: `${plannerForm.destination} Trip`,
        destination: plannerForm.destination,
        startDate: plannerForm.startDate,
        endDate: plannerForm.endDate,
        travelersCount: plannerForm.travelersCount,
        budget: plannerForm.budget,
        optimizedCost: optCost,
        transportType: 'Train',
        hotelName: 'Beach Resort Goa',
        status: 'upcoming',
        itinerary: {
          'Day 1': [
            { time: '09:00 AM', title: 'Arrive at destination', description: 'Check-in and settle in.', cost: 0, category: 'stay' }
          ]
        }
      };
      setTrips(prev => [newTrip, ...prev]);
      setCurrentTrip(newTrip);
    }
  };

  const handleAddExpense = async (e) => {
    e.preventDefault();
    if (!newExpenseForm.title || !newExpenseForm.amount) return;

    try {
      const res = await fetch(`${API_URL}/expenses`, {
        method: 'POST',
        headers: getHeaders(),
        body: JSON.stringify({
          tripId: currentTrip._id,
          title: newExpenseForm.title,
          amount: Number(newExpenseForm.amount),
          category: newExpenseForm.category
        })
      });
      if (res.ok) {
        setNewExpenseForm({ title: '', amount: '', category: 'food' });
        fetchExpenses(currentTrip._id);
        fetchExpenseStats(currentTrip._id);
      }
    } catch (err) {
      // Mock expense add
      const newExp = {
        _id: 'mock_exp_' + Date.now(),
        title: newExpenseForm.title,
        amount: Number(newExpenseForm.amount),
        category: newExpenseForm.category
      };
      setExpenses(prev => [newExp, ...prev]);
      // Update local stats
      const currentBreakdown = expenseStats?.breakdown || { transport: 0, stay: 0, food: 0, activities: 0, others: 0 };
      currentBreakdown[newExpenseForm.category] += Number(newExpenseForm.amount);
      setExpenseStats({
        totalSpent: (expenseStats?.totalSpent || 0) + Number(newExpenseForm.amount),
        breakdown: currentBreakdown
      });
      setNewExpenseForm({ title: '', amount: '', category: 'food' });
    }
  };

  const handleDeleteTrip = async (tripId) => {
    if (!window.confirm('Are you sure you want to delete this trip plan?')) return;
    try {
      const res = await fetch(`${API_URL}/trips/${tripId}`, {
        method: 'DELETE',
        headers: getHeaders()
      });
      if (res.ok) {
        const updated = trips.filter(t => t._id !== tripId);
        setTrips(updated);
        setCurrentTrip(updated[0] || null);
      }
    } catch (e) {
      const updated = trips.filter(t => t._id !== tripId);
      setTrips(updated);
      setCurrentTrip(updated[0] || null);
    }
  };

  const handleCompleteTrip = async (tripId) => {
    try {
      const res = await fetch(`${API_URL}/trips/${tripId}/status`, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify({ status: 'completed' })
      });
      if (res.ok) {
        alert('Trip marked as completed! You can find it in your Travel History.');
        fetchTrips();
      }
    } catch (e) {
      // Offline fallback
      setTrips(prev => prev.map(t => t._id === tripId ? { ...t, status: 'completed' } : t));
      alert('Trip marked as completed (Offline Mode)! You can find it in your Travel History.');
    }
  };

  // Auth Screen Layout
  if (!token) {
    return (
      <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#F8FAFC' }}>
        {/* Left Side Branding Banner */}
        <div style={{
          flex: 1, 
          background: 'linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%)',
          color: '#ffffff',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: '4rem',
          position: 'relative',
          overflow: 'hidden'
        }}>
          <div style={{
            position: 'absolute',
            width: '200px',
            height: '200px',
            background: 'rgba(255,255,255,0.05)',
            borderRadius: '50%',
            top: '-50px',
            right: '-50px'
          }}></div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '2rem' }}>
            <Compass size={40} style={{ strokeWidth: 2.5 }} />
            <h1 style={{ fontSize: '2.5rem', fontWeight: 800 }}>Smart Travel Planner</h1>
          </div>
          
          <h2 style={{ fontSize: '2rem', fontWeight: 700, marginBottom: '1.5rem', lineHeight: 1.2 }}>
            Plan smarter, travel better, and optimize your costs.
          </h2>
          <p style={{ color: 'rgba(255,255,255,0.8)', fontSize: '1.1rem', maxWidth: '500px', lineHeight: 1.6 }}>
            Our advanced AI algorithm analyzes flight routes, local transit, and stay accommodations to craft the absolute best travel itineraries within your target budget.
          </p>
        </div>

        {/* Right Side Form */}
        <div style={{ flex: 1.2, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '3rem' }}>
          <div style={{ width: '100%', maxWidth: '450px', padding: '2.5rem', backgroundColor: '#ffffff', borderRadius: '16px', boxShadow: '0 10px 25px -5px rgba(0,0,0,0.05)' }}>
            <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#0F172A', marginBottom: '0.5rem' }}>
              {authMode === 'login' ? 'Welcome Back!' : 'Create Account'}
            </h2>
            <p style={{ color: '#64748B', marginBottom: '2rem' }}>
              {authMode === 'login' ? 'Enter credentials to access your trips.' : 'Let\'s get started with your details.'}
            </p>

            {authError && (
              <div style={{ padding: '0.75rem', backgroundColor: '#FEE2E2', border: '1px solid #FCA5A5', color: '#B91C1C', borderRadius: '8px', fontSize: '0.875rem', marginBottom: '1.5rem' }}>
                {authError}
              </div>
            )}

            <form onSubmit={handleAuthSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              {authMode === 'signup' && (
                <div className="form-group">
                  <label className="form-label">Full NameLabel</label>
                  <input 
                    type="text" 
                    className="form-input" 
                    placeholder="Enter your name"
                    value={authForm.name} 
                    onChange={e => setAuthForm({ ...authForm, name: e.target.value })}
                    required
                  />
                </div>
              )}
              
              <div className="form-group">
                <label className="form-label">Email Address</label>
                <input 
                  type="email" 
                  className="form-input" 
                  placeholder="name@example.com"
                  value={authForm.email} 
                  onChange={e => setAuthForm({ ...authForm, email: e.target.value })}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Password</label>
                <input 
                  type="password" 
                  className="form-input" 
                  placeholder="••••••••"
                  value={authForm.password} 
                  onChange={e => setAuthForm({ ...authForm, password: e.target.value })}
                  required
                />
              </div>

              <button type="submit" className="btn btn-primary" style={{ padding: '0.85rem' }}>
                {authMode === 'login' ? 'Log In' : 'Sign Up'}
              </button>
            </form>

            <div style={{ marginTop: '2rem', textAlign: 'center', fontSize: '0.875rem', color: '#64748B' }}>
              {authMode === 'login' ? (
                <span>
                  Don't have an account?{' '}
                  <button 
                    onClick={() => { setAuthMode('signup'); setAuthError(''); }}
                    style={{ background: 'none', border: 'none', color: '#2563EB', fontWeight: 600, cursor: 'pointer' }}
                  >
                    Sign Up
                  </button>
                </span>
              ) : (
                <span>
                  Already have an account?{' '}
                  <button 
                    onClick={() => { setAuthMode('login'); setAuthError(''); }}
                    style={{ background: 'none', border: 'none', color: '#2563EB', fontWeight: 600, cursor: 'pointer' }}
                  >
                    Log In
                  </button>
                </span>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Visual Chart Data for optimization donut
  const breakdownData = optimizationResult?.breakdown || { transport: 8000, stay: 6000, food: 3000, activities: 2000, others: 1000 };
  const doughnutData = {
    labels: ['Transport', 'Stay', 'Food', 'Activities', 'Others'],
    datasets: [{
      data: [
        breakdownData.transport,
        breakdownData.stay,
        breakdownData.food,
        breakdownData.activities,
        breakdownData.others
      ],
      backgroundColor: ['#2563EB', '#10B981', '#F59E0B', '#EC4899', '#64748B'],
      borderColor: ['#ffffff', '#ffffff', '#ffffff', '#ffffff', '#ffffff'],
      borderWidth: 2
    }]
  };

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside style={{
        width: '280px',
        backgroundColor: '#1E293B',
        color: '#ffffff',
        display: 'flex',
        flexDirection: 'column',
        borderRight: '1px solid #334155'
      }}>
        {/* Profile Info Header */}
        <div style={{ padding: '2rem 1.5rem', display: 'flex', alignItems: 'center', gap: '1rem', borderBottom: '1px solid #334155' }}>
          <img 
            src={user?.avatar} 
            alt="Profile Avatar" 
            style={{ width: '48px', height: '48px', borderRadius: '50%', objectFit: 'cover', border: '2px solid #2563EB' }}
          />
          <div>
            <h3 style={{ fontSize: '1rem', fontWeight: 700 }}>{user?.name}</h3>
            <p style={{ fontSize: '0.75rem', color: '#94A3B8' }}>{user?.email}</p>
          </div>
        </div>

        {/* Navigation Tabs */}
        <nav style={{ padding: '2rem 1rem', display: 'flex', flexDirection: 'column', gap: '0.5rem', flex: 1 }}>
          <button 
            className={`btn ${currentTab === 'dashboard' ? 'btn-primary' : 'btn-outline'}`}
            style={{ justifyContent: 'flex-start', color: currentTab === 'dashboard' ? '#ffffff' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('dashboard')}
          >
            <Compass size={18} /> Dashboard
          </button>
          
          <button 
            className={`btn ${currentTab === 'planner' ? 'btn-primary' : 'btn-outline'}`}
            style={{ justifyContent: 'flex-start', color: currentTab === 'planner' ? '#ffffff' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('planner')}
          >
            <Calendar size={18} /> Trip Planner
          </button>

          <button 
            className={`btn ${currentTab === 'history' ? 'btn-primary' : 'btn-outline'}`}
            style={{ justifyContent: 'flex-start', color: currentTab === 'history' ? '#ffffff' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('history')}
          >
            <History size={18} /> Travel History
          </button>

          <button 
            className={`btn ${currentTab === 'bookings' ? 'btn-primary' : 'btn-outline'}`}
            style={{ justifyContent: 'flex-start', color: currentTab === 'bookings' ? '#ffffff' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('bookings')}
          >
            <Hotel size={18} /> Bookings
          </button>

          <button 
            className={`btn ${currentTab === 'expenses' ? 'btn-primary' : 'btn-outline'}`}
            style={{ justifyContent: 'flex-start', color: currentTab === 'expenses' ? '#ffffff' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('expenses')}
          >
            <TrendingUp size={18} /> Expense Tracker
          </button>

          <button 
            className={`btn ${currentTab === 'profile' ? 'btn-primary' : 'btn-outline'}`}
            style={{ justifyContent: 'flex-start', color: currentTab === 'profile' ? '#ffffff' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('profile')}
          >
            <User size={18} /> User Profile
          </button>

          <button 
            className={`btn ${currentTab === 'settings' ? 'btn-primary' : 'btn-outline'}`}
            style={{ justifyContent: 'flex-start', color: currentTab === 'settings' ? '#ffffff' : '#94A3B8', border: 'none' }}
            onClick={() => setCurrentTab('settings')}
          >
            <Settings size={18} /> Settings
          </button>
        </nav>

        {/* Log Out button */}
        <div style={{ padding: '1.5rem', borderTop: '1px solid #334155' }}>
          <button 
            onClick={handleLogout}
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '0.5rem',
              backgroundColor: '#EF4444',
              color: '#ffffff',
              padding: '0.75rem',
              border: 'none',
              borderRadius: '8px',
              fontWeight: 600,
              cursor: 'pointer'
            }}
          >
            <LogOut size={18} /> Log Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        
        {/* VIEW 1: DASHBOARD */}
        {currentTab === 'dashboard' && (
          <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <header style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h1 style={{ color: '#0F172A' }}>Hello, {user?.name.split(' ')[0]}! 👋</h1>
                <p>Welcome back. Plan smart and save on your next vacation.</p>
              </div>
              <div style={{ position: 'relative', cursor: 'pointer' }}>
                <div style={{
                  position: 'absolute',
                  top: '-2px',
                  right: '-2px',
                  backgroundColor: '#EF4444',
                  color: '#ffffff',
                  fontSize: '0.65rem',
                  padding: '2px 5px',
                  borderRadius: '50%',
                  fontWeight: 700
                }}>3</div>
                <Bell size={24} style={{ color: '#64748B' }} />
              </div>
            </header>

            {/* Selection Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
              
              {/* Card 1: Active Trip Plan */}
              <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', height: '220px' }}>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
                    <span className="badge badge-primary">Active Itinerary</span>
                    <span style={{ fontSize: '0.875rem', color: '#64748B', fontWeight: 500 }}>
                      {currentTrip ? `${new Date(currentTrip.startDate).toLocaleDateString()} - ${new Date(currentTrip.endDate).toLocaleDateString()}` : 'No active trips'}
                    </span>
                  </div>
                  <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: '#0F172A', marginBottom: '0.5rem' }}>
                    {currentTrip ? currentTrip.title : 'Plan a New Journey'}
                  </h3>
                  {currentTrip && (
                    <p style={{ fontSize: '0.875rem' }}>
                      Hotel: <strong>{currentTrip.hotelName}</strong> | Transport: <strong>{currentTrip.transportType}</strong>
                    </p>
                  )}
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  {currentTrip ? (
                    <>
                      <div style={{ display: 'flex', flexDirection: 'column' }}>
                        <span style={{ fontSize: '0.75rem', color: '#94A3B8' }}>Optimized Cost</span>
                        <span style={{ fontSize: '1.5rem', fontWeight: 800, color: '#10B981' }}>₹{currentTrip.optimizedCost.toLocaleString()}</span>
                      </div>
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        {currentTrip.status === 'upcoming' && (
                          <button 
                            className="btn btn-success" 
                            style={{ padding: '0.5rem 1.25rem', fontSize: '0.875rem', backgroundColor: '#10B981', color: '#ffffff', border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 600 }}
                            onClick={() => handleCompleteTrip(currentTrip._id)}
                          >
                            Complete
                          </button>
                        )}
                        <button 
                          className="btn btn-outline" 
                          style={{ padding: '0.5rem 1rem', fontSize: '0.875rem' }}
                          onClick={() => setCurrentTab('planner')}
                        >
                          Details
                        </button>
                      </div>
                    </>
                  ) : (
                    <button className="btn btn-primary" onClick={() => setCurrentTab('planner')}>
                      Create a Plan <ArrowRight size={16} />
                    </button>
                  )}
                </div>
              </div>

              {/* Card 2: Cost Savings breakdown */}
              {currentTrip && (
                <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', height: '220px' }}>
                  <div>
                    <span className="badge badge-success" style={{ marginBottom: '1rem' }}>Smart Optimization</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
                      <TrendingDown size={32} style={{ color: '#10B981' }} />
                      <div>
                        <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: '#10B981' }}>
                          ₹{(currentTrip.budget - currentTrip.optimizedCost).toLocaleString()}
                        </h3>
                        <p style={{ fontSize: '0.75rem', margin: 0 }}>Saved by choosing Smart Budget Plan</p>
                      </div>
                    </div>
                  </div>
                  <p style={{ fontSize: '0.85rem', color: '#64748B', lineHeight: 1.4 }}>
                    Your transport was optimized to <strong>{currentTrip.transportType}</strong> and hotel package to <strong>Deluxe Room</strong> matching optimal metrics.
                  </p>
                </div>
              )}

              {/* Card 3: Destinations list shortcut */}
              <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', height: '220px' }}>
                <div>
                  <span className="badge badge-warning" style={{ marginBottom: '1rem' }}>Popular Searches</span>
                  <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginTop: '0.5rem' }}>
                    {destinations.slice(0,4).map(d => (
                      <span 
                        key={d.name} 
                        style={{ padding: '0.35rem 0.75rem', backgroundColor: '#F1F5F9', borderRadius: '20px', fontSize: '0.8rem', fontWeight: 600, color: '#334155', cursor: 'pointer' }}
                        onClick={() => {
                          setPlannerForm({ ...plannerForm, destination: d.name });
                          setCurrentTab('planner');
                        }}
                      >
                        {d.name} (★ {d.rating})
                      </span>
                    ))}
                  </div>
                </div>
                <button 
                  className="btn btn-outline" 
                  style={{ width: '100%', padding: '0.5rem', fontSize: '0.85rem', gap: '0.25rem' }}
                  onClick={() => setCurrentTab('planner')}
                >
                  Explore Destinations <ChevronRight size={14} />
                </button>
              </div>

            </div>

            {/* Main Split Section: Itinerary vs Popular Destinations list */}
            <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '2rem', marginTop: '1rem' }}>
              
              {/* Left Column: Itinerary Timeline */}
              <div className="card">
                <h3 style={{ fontSize: '1.25rem', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <Navigation size={20} style={{ color: '#2563EB' }} />
                  Itinerary: {currentTrip ? currentTrip.title : 'Trip Plan Itinerary'}
                </h3>
                
                {currentTrip && currentTrip.itinerary ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                    <div>
                      <h4 style={{ fontSize: '0.95rem', fontWeight: 700, color: '#475569', marginBottom: '0.5rem' }}>Interactive Route Tracker</h4>
                      <TripMap 
                        activities={enrichActivitiesWithCoords(currentTrip.destination, getAllTripActivities(currentTrip))} 
                        destinationCoords={destCoordsMap[currentTrip.destination] || [15.2993, 74.1240]} 
                      />
                    </div>

                    {Object.keys(currentTrip.itinerary).map(dayKey => (
                      <div key={dayKey}>
                        <h4 style={{ color: '#2563EB', fontWeight: 700, borderBottom: '1px solid #E2E8F0', paddingBottom: '0.25rem', marginBottom: '1rem', marginTop: '1rem' }}>
                          {dayKey}
                        </h4>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', paddingLeft: '0.5rem' }}>
                          {currentTrip.itinerary[dayKey].map((act, index) => (
                            <div key={index} style={{ display: 'flex', gap: '1rem', position: 'relative' }}>
                              <div style={{
                                width: '12px',
                                height: '12px',
                                borderRadius: '50%',
                                backgroundColor: act.category === 'transport' ? '#2563EB' : act.category === 'stay' ? '#10B981' : '#F59E0B',
                                marginTop: '6px',
                                flexShrink: 0
                              }}></div>
                              <div style={{ flex: 1 }}>
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                  <span style={{ fontSize: '0.75rem', fontWeight: 600, color: '#94A3B8' }}>{act.time}</span>
                                  {act.cost > 0 && <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#475569' }}>₹{act.cost}</span>}
                                </div>
                                <h5 style={{ fontWeight: 600, fontSize: '0.95rem', color: '#1F2937' }}>{act.title}</h5>
                                <p style={{ fontSize: '0.85rem', color: '#64748B', marginTop: '0.15rem' }}>{act.description}</p>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div style={{ padding: '2rem 0', textAlign: 'center', color: '#94A3B8' }}>
                    No itinerary selected. Use the Trip Planner to create one.
                  </div>
                )}
              </div>

              {/* Right Column: Trips Listing and Destinations Cards */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                
                {/* User's planned trips */}
                <div className="card">
                  <h3 style={{ fontSize: '1.15rem', marginBottom: '1rem' }}>Your Saved Trips</h3>
                  {trips.length > 0 ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                      {trips.map(t => (
                        <div 
                          key={t._id} 
                          style={{
                            padding: '1rem',
                            border: `1px solid ${currentTrip?._id === t._id ? '#2563EB' : '#E2E8F0'}`,
                            borderRadius: '8px',
                            cursor: 'pointer',
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            backgroundColor: currentTrip?._id === t._id ? 'rgba(37, 99, 235, 0.02)' : '#ffffff'
                          }}
                          onClick={() => setCurrentTrip(t)}
                        >
                          <div>
                            <h4 style={{ fontWeight: 700, fontSize: '0.95rem' }}>{t.title}</h4>
                            <span style={{ fontSize: '0.75rem', color: '#94A3B8' }}>₹{t.optimizedCost.toLocaleString()}</span>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <ChevronRight size={16} style={{ color: '#94A3B8' }} />
                            <button 
                              onClick={(e) => { e.stopPropagation(); handleDeleteTrip(t._id); }}
                              style={{ background: 'none', border: 'none', color: '#EF4444', cursor: 'pointer', padding: '0.25rem' }}
                            >
                              <Trash2 size={14} />
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p style={{ fontSize: '0.85rem', color: '#94A3B8' }}>No saved trip plans found.</p>
                  )}
                </div>

                {/* Popular Destinations Cards */}
                <div className="card">
                  <h3 style={{ fontSize: '1.15rem', marginBottom: '1rem' }}>Top Destinations</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {destinations.slice(0, 3).map(dest => (
                      <div key={dest.name} style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                        <img 
                          src={dest.imageUrl} 
                          alt={dest.name} 
                          style={{ width: '60px', height: '60px', borderRadius: '8px', objectFit: 'cover' }}
                        />
                        <div>
                          <h4 style={{ fontSize: '0.95rem', fontWeight: 700, margin: 0 }}>{dest.name}</h4>
                          <span style={{ fontSize: '0.75rem', color: '#F59E0B', fontWeight: 600 }}>★ {dest.rating}</span>
                          <p style={{ fontSize: '0.75rem', color: '#64748B', display: '-webkit-box', WebkitLineClamp: 1, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                            {dest.description}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

              </div>

            </div>
          </div>
        )}

        {/* VIEW 2: TRIP PLANNER & BUDGET OPTIMIZER */}
        {currentTab === 'planner' && (
          <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <header>
              <h1 style={{ color: '#0F172A' }}>Cost Optimisation Trip Planner</h1>
              <p>Setup your trip parameters, and our system will design the most budget-optimized travel solution.</p>
            </header>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr', gap: '2.5rem' }}>
              {/* Form Input */}
              <div className="card">
                <h3 style={{ fontSize: '1.25rem', marginBottom: '1.5rem' }}>Plan Your Trip</h3>
                
                <form onSubmit={runPlannerOptimization} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  <div className="form-group">
                    <label className="form-label">Destination</label>
                    <select 
                      className="form-input"
                      value={plannerForm.destination}
                      onChange={e => setPlannerForm({ ...plannerForm, destination: e.target.value })}
                    >
                      <option value="Goa">Goa (Beach Paradise)</option>
                      <option value="Manali">Manali (Mountain valley)</option>
                      <option value="Kerala">Kerala (Houseboats & Nature)</option>
                      <option value="Dubai">Dubai (Luxury Desert Resort)</option>
                      <option value="Shimla">Shimla (Hill Station & Heritage)</option>
                      <option value="Jaipur">Jaipur (Pink City & Heritage)</option>
                      <option value="Leh Ladakh">Leh Ladakh (High Altitude & Adventure)</option>
                    </select>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                    <div className="form-group">
                      <label className="form-label">Departure Date</label>
                      <input 
                        type="date" 
                        className="form-input"
                        value={plannerForm.startDate}
                        onChange={e => setPlannerForm({ ...plannerForm, startDate: e.target.value })}
                      />
                    </div>
                    <div className="form-group">
                      <label className="form-label">Return Date</label>
                      <input 
                        type="date" 
                        className="form-input"
                        value={plannerForm.endDate}
                        onChange={e => setPlannerForm({ ...plannerForm, endDate: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="form-group">
                    <label className="form-label">Number of Travelers</label>
                    <input 
                      type="number" 
                      min="1" 
                      className="form-input"
                      value={plannerForm.travelersCount}
                      onChange={e => setPlannerForm({ ...plannerForm, travelersCount: Number(e.target.value) })}
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Target Budget (INR)</label>
                    <div style={{ position: 'relative' }}>
                      <span style={{ position: 'absolute', left: '12px', top: '10px', fontWeight: 600, color: '#64748B' }}>₹</span>
                      <input 
                        type="number" 
                        className="form-input"
                        style={{ paddingLeft: '24px' }}
                        value={plannerForm.budget}
                        onChange={e => setPlannerForm({ ...plannerForm, budget: Number(e.target.value) })}
                      />
                    </div>
                  </div>

                  <button type="submit" className="btn btn-primary" style={{ padding: '0.85rem' }}>
                    Optimize Budget & Generate Plan
                  </button>
                </form>
              </div>

              {/* Optimization Result Display */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                {optimizationResult ? (
                  <div className="card animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                    
                    {/* Header comparison */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #E2E8F0', paddingBottom: '1.25rem' }}>
                      <div>
                        <span className="badge badge-success">Optimisation Found</span>
                        <h3 style={{ fontSize: '1.5rem', fontWeight: 800, marginTop: '0.5rem', color: '#10B981' }}>
                          ₹{optimizationResult.optimizedCost.toLocaleString()}
                        </h3>
                        <p style={{ fontSize: '0.75rem', margin: 0 }}>Target Budget: ₹{plannerForm.budget.toLocaleString()}</p>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <span style={{ fontSize: '0.75rem', color: '#94A3B8' }}>Smart Savings</span>
                        <h4 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#10B981' }}>
                          - ₹{optimizationResult.savings.toLocaleString()}
                        </h4>
                      </div>
                    </div>

                    {/* Donut Chart representation */}
                    <div style={{ display: 'flex', gap: '2rem', alignItems: 'center' }}>
                      <div style={{ width: '150px', height: '150px' }}>
                        <Doughnut 
                          data={doughnutData} 
                          options={{
                            plugins: { legend: { display: false } },
                            cutout: '65%'
                          }}
                        />
                      </div>
                      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                        <h4 style={{ fontSize: '0.9rem', fontWeight: 700, color: '#1F2937' }}>Optimized Cost Breakdown</h4>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', fontSize: '0.8rem' }}>
                          <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between' }}>
                            <span style={{ color: '#2563EB', fontWeight: 600 }}>■ Transport</span>
                            <span>₹{optimizationResult.breakdown.transport.toLocaleString()} (40%)</span>
                          </div>
                          <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between' }}>
                            <span style={{ color: '#10B981', fontWeight: 600 }}>■ Stay</span>
                            <span>₹{optimizationResult.breakdown.stay.toLocaleString()} (30%)</span>
                          </div>
                          <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between' }}>
                            <span style={{ color: '#F59E0B', fontWeight: 600 }}>■ Food</span>
                            <span>₹{optimizationResult.breakdown.food.toLocaleString()} (15%)</span>
                          </div>
                          <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between' }}>
                            <span style={{ color: '#EC4899', fontWeight: 600 }}>■ Activities</span>
                            <span>₹{optimizationResult.breakdown.activities.toLocaleString()} (10%)</span>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Recommendations Alerts */}
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', backgroundColor: '#F8FAFC', padding: '1rem', borderRadius: '12px', border: '1px solid #E2E8F0' }}>
                      <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-start' }}>
                        <Check size={16} style={{ color: '#10B981', marginTop: '3px', flexShrink: 0 }} />
                        <p style={{ fontSize: '0.85rem', margin: 0 }}>
                          <strong>Transport:</strong> {optimizationResult.transportRecommendation}
                        </p>
                      </div>
                      <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-start' }}>
                        <Check size={16} style={{ color: '#10B981', marginTop: '3px', flexShrink: 0 }} />
                        <p style={{ fontSize: '0.85rem', margin: 0 }}>
                          <strong>Accommodation:</strong> {optimizationResult.stayRecommendation}
                        </p>
                      </div>
                    </div>

                    <button 
                      className="btn btn-success" 
                      style={{ padding: '0.85rem' }}
                      onClick={() => {
                        alert('Trip plan saved! It has been set as your active itinerary.');
                        setCurrentTab('dashboard');
                      }}
                    >
                      Accept Optimized Plan & Save Trip
                    </button>

                  </div>
                ) : (
                  <div className="card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifySelf: 'center', padding: '4rem 2rem', textAlign: 'center', color: '#94A3B8' }}>
                    <Compass size={48} style={{ strokeWidth: 1.5, marginBottom: '1.5rem', color: '#CBD5E1' }} />
                    <h3>No Optimization Run</h3>
                    <p style={{ maxWidth: '300px', fontSize: '0.875rem', marginTop: '0.5rem' }}>
                      Submit the planning form to analyze transit options and stays.
                    </p>
                  </div>
                )}
              </div>
            </div>

          </div>
        )}

        {/* VIEW 3: BOOKINGS */}
        {currentTab === 'bookings' && (
          <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <header>
              <h1 style={{ color: '#0F172A' }}>Your Booked Resources</h1>
              <p>Hotels, stays, flights, and trains currently confirmed for your travel itineraries.</p>
            </header>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.5rem' }}>
              {bookings.map(book => (
                <div className="card" key={book._id} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <span className={`badge ${book.type === 'hotel' ? 'badge-success' : 'badge-primary'}`}>
                      {book.type.toUpperCase()}
                    </span>
                    <span style={{ fontSize: '0.75rem', color: '#94A3B8', fontWeight: 600 }}>{book.bookingIdString}</span>
                  </div>
                  
                  <div>
                    <h3 style={{ fontSize: '1.2rem', color: '#1F2937', fontWeight: 700 }}>{book.name}</h3>
                    <p style={{ fontSize: '0.85rem', color: '#64748B' }}>{book.details}</p>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid #F1F5F9', paddingTop: '1rem' }}>
                    <span style={{ fontSize: '1.25rem', fontWeight: 800, color: '#1F2937' }}>₹{book.cost.toLocaleString()}</span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.8rem', color: '#10B981', fontWeight: 600 }}>
                      <CheckCircle size={14} /> Confirmed
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* VIEW 4: EXPENSE TRACKER */}
        {currentTab === 'expenses' && (
          <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <header>
              <h1 style={{ color: '#0F172A' }}>Expense Tracker & Analytics</h1>
              <p>Track real-time spendings and compare them against your target optimized budget.</p>
            </header>

            {currentTrip ? (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: '2.5rem' }}>
                {/* Left Side: Add Expense and Stats */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem' }}>
                  {/* Summary */}
                  <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div>
                      <span style={{ fontSize: '0.75rem', color: '#94A3B8' }}>Total Spent</span>
                      <h2 style={{ fontSize: '2.25rem', fontWeight: 800, color: '#1F2937' }}>
                        ₹{expenseStats ? expenseStats.totalSpent.toLocaleString() : '0'}
                      </h2>
                    </div>
                    <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between', fontSize: '0.85rem', borderTop: '1px solid #E2E8F0', paddingTop: '1rem' }}>
                      <span>Optimized Target: <strong>₹{currentTrip.optimizedCost.toLocaleString()}</strong></span>
                      <span style={{ color: '#10B981', fontWeight: 700 }}>On Track</span>
                    </div>
                  </div>

                  {/* Add Expense Form */}
                  <div className="card">
                    <h3 style={{ fontSize: '1.2rem', marginBottom: '1rem' }}>Log New Expense</h3>
                    <form onSubmit={handleAddExpense} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                      <div className="form-group">
                        <label className="form-label">Expense Title</label>
                        <input 
                          type="text" 
                          className="form-input"
                          placeholder="e.g. Dinner at Shack"
                          value={newExpenseForm.title}
                          onChange={e => setNewExpenseForm({ ...newExpenseForm, title: e.target.value })}
                          required
                        />
                      </div>
                      
                      <div className="form-group">
                        <label className="form-label">Amount (INR)</label>
                        <input 
                          type="number" 
                          className="form-input"
                          placeholder="₹"
                          value={newExpenseForm.amount}
                          onChange={e => setNewExpenseForm({ ...newExpenseForm, amount: e.target.value })}
                          required
                        />
                      </div>

                      <div className="form-group">
                        <label className="form-label">Category</label>
                        <select 
                          className="form-input"
                          value={newExpenseForm.category}
                          onChange={e => setNewExpenseForm({ ...newExpenseForm, category: e.target.value })}
                        >
                          <option value="transport">Transport</option>
                          <option value="stay">Stay</option>
                          <option value="food">Food</option>
                          <option value="activities">Activities</option>
                          <option value="others">Others</option>
                        </select>
                      </div>

                      <button type="submit" className="btn btn-primary" style={{ padding: '0.75rem' }}>
                        Add Expense
                      </button>
                    </form>
                  </div>
                </div>

                {/* Right Side: Expense List */}
                <div className="card">
                  <h3 style={{ fontSize: '1.25rem', marginBottom: '1.5rem' }}>Logged Expenses List</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {expenses.map(exp => (
                      <div 
                        key={exp._id}
                        style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center',
                          padding: '1rem',
                          border: '1px solid #E2E8F0',
                          borderRadius: '8px'
                        }}
                      >
                        <div>
                          <h4 style={{ fontWeight: 700, fontSize: '0.95rem' }}>{exp.title}</h4>
                          <span className={`badge ${
                            exp.category === 'transport' ? 'badge-primary' : 
                            exp.category === 'stay' ? 'badge-success' : 'badge-warning'
                          }`} style={{ marginTop: '0.25rem' }}>
                            {exp.category}
                          </span>
                        </div>
                        <span style={{ fontSize: '1.15rem', fontWeight: 800 }}>₹{exp.amount.toLocaleString()}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="card" style={{ padding: '4rem', textAlign: 'center', color: '#94A3B8' }}>
                Please create a trip in the planner before logging expenses.
              </div>
            )}
          </div>
        )}

        {/* VIEW 5: USER PROFILE */}
        {currentTab === 'profile' && (
          <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <header>
              <h1 style={{ color: '#0F172A' }}>My Profile Details</h1>
              <p>Manage your account credentials, documents, and preferences.</p>
            </header>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '2.5rem' }}>
              {/* Profile Card */}
              <div className="card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1.5rem', textAlign: 'center' }}>
                <img 
                  src={user?.avatar} 
                  alt="User Avatar" 
                  style={{ width: '120px', height: '120px', borderRadius: '50%', border: '4px solid #2563EB', objectFit: 'cover' }}
                />
                <div>
                  <h2 style={{ fontSize: '1.5rem', fontWeight: 800 }}>{user?.name}</h2>
                  <p>{user?.email}</p>
                </div>
                <div style={{ borderTop: '1px solid #E2E8F0', width: '100%', paddingTop: '1rem', display: 'flex', justifySelf: 'stretch', justifyContent: 'space-around', fontSize: '0.85rem' }}>
                  <div>
                    <strong>{trips.length}</strong>
                    <div style={{ color: '#94A3B8' }}>Trips Planned</div>
                  </div>
                  <div>
                    <strong>{bookings.length}</strong>
                    <div style={{ color: '#94A3B8' }}>Reservations</div>
                  </div>
                </div>
              </div>

              {/* Information list */}
              <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <h3 style={{ fontSize: '1.25rem' }}>Personal Information</h3>
                
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
                  <div className="form-group">
                    <label className="form-label">Full Name</label>
                    <input type="text" className="form-input" value={user?.name} readOnly />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Email Address</label>
                    <input type="email" className="form-input" value={user?.email} readOnly />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Mobile Number</label>
                    <input type="text" className="form-input" value="+91 98765 43210" readOnly />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Nationality</label>
                    <input type="text" className="form-input" value="Indian" readOnly />
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* VIEW 6: SETTINGS */}
        {currentTab === 'settings' && (
          <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <header>
              <h1 style={{ color: '#0F172A' }}>Application Settings</h1>
              <p>Configure notifications, local currency display, and dark mode toggles.</p>
            </header>

            <div className="card" style={{ maxWidth: '650px', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #F1F5F9', paddingBottom: '1rem' }}>
                <div>
                  <h4 style={{ fontWeight: 700 }}>Push Notifications</h4>
                  <p style={{ fontSize: '0.85rem' }}>Receive updates on price drops and confirmation updates.</p>
                </div>
                <input type="checkbox" defaultChecked style={{ width: '20px', height: '20px', cursor: 'pointer' }} />
              </div>

              <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #F1F5F9', paddingBottom: '1rem' }}>
                <div>
                  <h4 style={{ fontWeight: 700 }}>Dark Mode</h4>
                  <p style={{ fontSize: '0.85rem' }}>Switch system interface colors to a dark palette.</p>
                </div>
                <input type="checkbox" style={{ width: '20px', height: '20px', cursor: 'pointer' }} />
              </div>

              <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #F1F5F9', paddingBottom: '1rem' }}>
                <div>
                  <h4 style={{ fontWeight: 700 }}>Base Currency Display</h4>
                  <p style={{ fontSize: '0.85rem' }}>Select standard currency for cost optimization comparison.</p>
                </div>
                <select className="form-input" style={{ width: '120px', padding: '0.4rem' }} defaultValue="INR">
                  <option value="INR">INR (₹)</option>
                  <option value="USD">USD ($)</option>
                  <option value="EUR">EUR (€)</option>
                </select>
              </div>

              <div style={{ display: 'flex', justifySelf: 'stretch', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h4 style={{ fontWeight: 700 }}>Language</h4>
                  <p style={{ fontSize: '0.85rem' }}>Select the main system interface language.</p>
                </div>
                <select className="form-input" style={{ width: '120px', padding: '0.4rem' }} defaultValue="en">
                  <option value="en">English</option>
                  <option value="es">Spanish</option>
                  <option value="fr">French</option>
                </select>
              </div>
            </div>
          </div>
        )}

        {/* VIEW 7: TRAVEL HISTORY */}
        {currentTab === 'history' && (
          <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <header>
              <h1 style={{ color: '#0F172A' }}>Your Travel History</h1>
              <p>Relive your completed journeys and see how much you saved with our AI suggestions.</p>
            </header>

            {trips.filter(t => t.status === 'completed').length > 0 ? (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(380px, 1fr))', gap: '1.5rem' }}>
                {trips.filter(t => t.status === 'completed').map(trip => {
                  const savings = trip.budget - trip.optimizedCost;
                  const activities = getAllTripActivities(trip);
                  const destCoords = destCoordsMap[trip.destination] || [15.2993, 74.1240];
                  return (
                    <div className="card" key={trip._id} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span className="badge badge-success" style={{ backgroundColor: '#10B981', color: '#ffffff' }}>Completed</span>
                        <span style={{ fontSize: '0.8rem', color: '#64748B', fontWeight: 500 }}>
                          {new Date(trip.startDate).toLocaleDateString()} - {new Date(trip.endDate).toLocaleDateString()}
                        </span>
                      </div>
                      <div>
                        <h3 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#0F172A', marginBottom: '0.25rem' }}>
                          {trip.title}
                        </h3>
                        <p style={{ fontSize: '0.85rem', color: '#64748B', margin: 0 }}>
                          Stayed at: <strong>{trip.hotelName}</strong> | Transport: <strong>{trip.transportType}</strong>
                        </p>
                      </div>

                      <div style={{ display: 'flex', justifyContent: 'space-between', backgroundColor: '#F8FAFC', padding: '0.75rem 1rem', borderRadius: '8px', border: '1px solid #E2E8F0' }}>
                        <div>
                          <span style={{ fontSize: '0.7rem', color: '#94A3B8', display: 'block' }}>Cost Paid</span>
                          <span style={{ fontSize: '1rem', fontWeight: 800, color: '#0F172A' }}>₹{trip.optimizedCost.toLocaleString()}</span>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <span style={{ fontSize: '0.7rem', color: '#10B981', display: 'block', fontWeight: 600 }}>Total Saved</span>
                          <span style={{ fontSize: '1rem', fontWeight: 800, color: '#10B981' }}>₹{savings.toLocaleString()}</span>
                        </div>
                      </div>

                      <div style={{ borderTop: '1px solid #F1F5F9', paddingTop: '1rem' }}>
                        <h4 style={{ fontSize: '0.9rem', fontWeight: 700, marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.25rem', color: '#1F2937' }}>
                          <Navigation size={14} style={{ color: '#2563EB' }} /> Route Map Tracker
                        </h4>
                        <TripMap activities={enrichActivitiesWithCoords(trip.destination, activities)} destinationCoords={destCoords} />
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '4rem 2rem', textAlign: 'center', color: '#94A3B8' }}>
                <Clock size={48} style={{ strokeWidth: 1.5, marginBottom: '1.5rem', color: '#CBD5E1' }} />
                <h3>No Completed Trips</h3>
                <p style={{ maxWidth: '350px', fontSize: '0.875rem', marginTop: '0.5rem' }}>
                  Mark your upcoming trips as "completed" from the active itinerary card on the dashboard to view them in your travel history.
                </p>
              </div>
            )}
          </div>
        )}

      </main>
    </div>
  );
}
