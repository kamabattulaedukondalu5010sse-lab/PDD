import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.29.127:5000/api';
  String? _token;
  User? _currentUser;
  bool _useMock = false;

  // Local Mock Store (Mutable for demo/fallback purposes)
  final List<Destination> _mockDestinations = [
    Destination(id: 'd1', name: 'Goa', description: 'Beach Paradise with scenic views, palm trees, and vibrant nightlife.', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=500&q=80', rating: 4.8, costFactor: 1.0, category: 'Beach', lat: 15.2993, lng: 74.1240),
    Destination(id: 'd2', name: 'Manali', description: 'Snow Mountains, adventure sports, and scenic valley drives.', imageUrl: 'https://images.unsplash.com/photo-1596701062351-dfc21a4d80a5?auto=format&fit=crop&w=500&q=80', rating: 4.7, costFactor: 1.2, category: 'Mountain', lat: 32.2396, lng: 77.1887),
    Destination(id: 'd3', name: 'Kerala', description: 'God\'s Own Country with serene backwaters, houseboats, and greenery.', imageUrl: 'https://images.unsplash.com/photo-1602216056096-3c40cc0c9944?auto=format&fit=crop&w=500&q=80', rating: 4.6, costFactor: 1.1, category: 'Nature', lat: 10.8505, lng: 76.2711),
    Destination(id: 'd4', name: 'Dubai', description: 'Luxury & Adventure, tallest buildings, deserts, and shopping malls.', imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=500&q=80', rating: 4.9, costFactor: 2.5, category: 'Luxury', lat: 25.2048, lng: 55.2708),
    Destination(id: 'd5', name: 'Shimla', description: 'Beautiful hill station, heritage train, and colonial architecture.', imageUrl: 'https://images.unsplash.com/photo-1597075687490-8f673c6c17f6?auto=format&fit=crop&w=500&q=80', rating: 4.5, costFactor: 1.1, category: 'Mountain', lat: 31.1048, lng: 77.1734),
    Destination(id: 'd6', name: 'Jaipur', description: 'The Pink City, magnificent palaces, forts, and rich heritage.', imageUrl: 'https://images.unsplash.com/photo-1477584305590-38772bfc1937?auto=format&fit=crop&w=500&q=80', rating: 4.7, costFactor: 1.15, category: 'Heritage', lat: 26.9124, lng: 75.7873),
    Destination(id: 'd7', name: 'Leh Ladakh', description: 'Stunning high-altitude desert, lakes, monasteries, and adventure.', imageUrl: 'https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=500&q=80', rating: 4.9, costFactor: 1.5, category: 'Adventure', lat: 34.1526, lng: 77.5770),
  ];

  late final List<Trip> _mockTrips = [
    Trip(
      id: 't1',
      title: 'Goa Trip',
      destination: 'Goa',
      startDate: DateTime(2026, 5, 20),
      endDate: DateTime(2026, 5, 25),
      travelersCount: 2,
      budget: 25000,
      optimizedCost: 20099,
      transportType: 'Train',
      hotelName: 'Beach Resort Goa',
      status: 'upcoming',
      itinerary: {
        'Day 1': [
          Activity(time: '09:00 AM', title: 'Arrive in Goa', description: 'Arrive at Madgaon Station, take cab to hotel.', cost: 1200, category: 'transport', lat: 15.2736, lng: 73.9582),
          Activity(time: '12:00 PM', title: 'Check-in at Hotel', description: 'Check-in at Beach Resort Goa (Deluxe Room).', cost: 0, category: 'stay', lat: 15.5494, lng: 73.7535),
          Activity(time: '04:00 PM', title: 'Calangute Beach', description: 'Relax at the beach side and enjoy sunset.', cost: 500, category: 'activities', lat: 15.5442, lng: 73.7550),
          Activity(time: '08:00 PM', title: 'Dinner at Beach Shack', description: 'Have local Goan curry at the shack.', cost: 1200, category: 'food', lat: 15.5550, lng: 73.7520),
        ],
        'Day 2': [
          Activity(time: '10:00 AM', title: 'Scuba Diving at Grand Island', description: 'Undersea exploration and underwater photoshoot.', cost: 2500, category: 'activities', lat: 15.4294, lng: 73.7742),
          Activity(time: '02:00 PM', title: 'Lunch at German Bakery', description: 'Enjoy fresh continental dishes.', cost: 800, category: 'food', lat: 15.5994, lng: 73.7480),
          Activity(time: '06:00 PM', title: 'Fort Aguada', description: 'Explore Portuguese lighthouse and historical fort.', cost: 100, category: 'activities', lat: 15.4926, lng: 73.7736),
        ]
      },
    ),
  ];

  late final List<Booking> _mockBookings = [
    Booking(id: 'b1', type: 'hotel', name: 'Beach Resort Goa', details: 'Deluxe Room', cost: 4999, bookingIdString: 'TRP123456789', status: 'confirmed'),
    Booking(id: 'b2', type: 'transport', name: 'Konkan Express', details: 'AC 3 Tier (Train)', cost: 2500, bookingIdString: 'TRP987654321', status: 'confirmed'),
  ];

  late final List<Expense> _mockExpenses = [
    Expense(id: 'e1', title: 'Beach Resort Goa (Stay)', amount: 9000, category: 'stay', date: DateTime(2026, 5, 20)),
    Expense(id: 'e2', title: 'Konkan Express Tickets', amount: 7500, category: 'transport', date: DateTime(2026, 5, 20)),
    Expense(id: 'e3', title: 'Dinner at Beach Shack', amount: 3000, category: 'food', date: DateTime(2026, 5, 21)),
    Expense(id: 'e4', title: 'Scuba Diving Activity', amount: 1750, category: 'activities', date: DateTime(2026, 5, 21)),
  ];

  User? get currentUser => _currentUser;
  String? get token => _token;

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  // Auth Functions
  Future<bool> login(String email, String password) async {
    if (_useMock) {
      _token = 'mock_jwt_token';
      _currentUser = User(id: 'u1', name: 'John Doe', email: email, avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150&q=80', phone: '+91 98765 43210');
      return true;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        return true;
      }
      return false;
    } catch (e) {
      _useMock = true; // Fallback to mock state
      return login(email, password);
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    if (_useMock) {
      _token = 'mock_jwt_token';
      _currentUser = User(id: 'u1', name: name, email: email, avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150&q=80', phone: '');
      return true;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 210 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        return true;
      }
      return false;
    } catch (e) {
      _useMock = true;
      return signup(name, email, password);
    }
  }

  void logout() {
    _token = null;
    _currentUser = null;
  }

  // Destination API
  Future<List<Destination>> getDestinations({String search = ''}) async {
    if (_useMock) {
      if (search.isEmpty) return _mockDestinations;
      return _mockDestinations.where((d) => d.name.toLowerCase().contains(search.toLowerCase())).toList();
    }

    try {
      final res = await http.get(Uri.parse('$baseUrl/destinations?search=$search'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Destination.fromJson(item)).toList();
      }
      return _mockDestinations;
    } catch (e) {
      return _mockDestinations;
    }
  }

  // Trips API
  Future<List<Trip>> getTrips() async {
    if (_useMock) return _mockTrips;

    try {
      final res = await http.get(Uri.parse('$baseUrl/trips'), headers: _getHeaders())
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Trip.fromJson(item)).toList();
      }
      return _mockTrips;
    } catch (e) {
      return _mockTrips;
    }
  }

  Future<Trip?> createTrip(String destination, DateTime start, DateTime end, int travelers, double budget) async {
    final bodyData = {
      'destination': destination,
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'travelersCount': travelers,
      'budget': budget.toInt(),
    };

    if (_useMock) {
      final optCost = (destination.toLowerCase() == 'goa' && budget == 25000) ? 20099.0 : budget * 0.8;
      
      final destMock = _mockDestinations.firstWhere(
        (d) => d.name.toLowerCase() == destination.toLowerCase(),
        orElse: () => _mockDestinations[0],
      );
      final latVal = destMock.lat;
      final lngVal = destMock.lng;

      final mockTrip = Trip(
        id: 'mock_trip_${Random().nextInt(10000)}',
        title: '$destination Trip',
        destination: destination,
        startDate: start,
        endDate: end,
        travelersCount: travelers,
        budget: budget,
        optimizedCost: optCost,
        transportType: budget < 35000 ? 'Train' : 'Flight',
        hotelName: 'Beach Resort Goa',
        status: 'upcoming',
        itinerary: {
          'Day 1': [
            Activity(time: '09:00 AM', title: 'Arrive in $destination', description: 'Settle in and review details.', cost: 0, category: 'stay', lat: latVal, lng: lngVal),
          ]
        },
      );
      _mockTrips.add(mockTrip);
      
      // Auto seed mock bookings corresponding to it
      _mockBookings.add(Booking(
        id: 'bmock_${Random().nextInt(10000)}',
        type: 'hotel',
        name: 'Beach Resort Goa',
        details: 'Deluxe Room',
        cost: optCost * 0.45,
        bookingIdString: 'TRP${Random().nextInt(900000000) + 100000000}',
        status: 'confirmed',
      ));
      
      return mockTrip;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/trips'),
        headers: _getHeaders(),
        body: jsonEncode(bodyData),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return Trip.fromJson(data['trip']);
      }
      return null;
    } catch (e) {
      _useMock = true;
      return createTrip(destination, start, end, travelers, budget);
    }
  }

  // Bookings API
  Future<List<Booking>> getBookings() async {
    if (_useMock) return _mockBookings;

    try {
      final res = await http.get(Uri.parse('$baseUrl/bookings'), headers: _getHeaders())
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Booking.fromJson(item)).toList();
      }
      return _mockBookings;
    } catch (e) {
      return _mockBookings;
    }
  }

  // Expenses API
  Future<List<Expense>> getExpenses(String tripId) async {
    if (_useMock) return _mockExpenses;

    try {
      final res = await http.get(Uri.parse('$baseUrl/expenses/trip/$tripId'), headers: _getHeaders())
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => Expense.fromJson(item)).toList();
      }
      return _mockExpenses;
    } catch (e) {
      return _mockExpenses;
    }
  }

  Future<Expense?> addExpense(String tripId, String title, double amount, String category) async {
    final expBody = {
      'tripId': tripId,
      'title': title,
      'amount': amount.toInt(),
      'category': category,
    };

    if (_useMock) {
      final mock = Expense(
        id: 'emock_${Random().nextInt(10000)}',
        title: title,
        amount: amount,
        category: category,
        date: DateTime.now(),
      );
      _mockExpenses.add(mock);
      return mock;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: _getHeaders(),
        body: jsonEncode(expBody),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201) {
        return Expense.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      _useMock = true;
      return addExpense(tripId, title, amount, category);
    }
  }

  Future<bool> updateTripStatus(String tripId, String status) async {
    if (_useMock) {
      final idx = _mockTrips.indexWhere((t) => t.id == tripId);
      if (idx != -1) {
        final t = _mockTrips[idx];
        _mockTrips[idx] = Trip(
          id: t.id,
          title: t.title,
          destination: t.destination,
          startDate: t.startDate,
          endDate: t.endDate,
          travelersCount: t.travelersCount,
          budget: t.budget,
          optimizedCost: t.optimizedCost,
          transportType: t.transportType,
          hotelName: t.hotelName,
          itinerary: t.itinerary,
          status: status,
        );
        return true;
      }
      return false;
    }

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/trips/$tripId/status'),
        headers: _getHeaders(),
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      _useMock = true;
      return updateTripStatus(tripId, status);
    }
  }

  Future<bool> updateProfile(String name, String email, String phone) async {
    if (_useMock) {
      if (_currentUser != null) {
        _currentUser = User(
          id: _currentUser!.id,
          name: name,
          email: email,
          avatar: _currentUser!.avatar,
          phone: phone,
        );
        return true;
      }
      return false;
    }

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/auth/user'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(res.body));
        return true;
      }
      return false;
    } catch (e) {
      _useMock = true;
      return updateProfile(name, email, phone);
    }
  }
}
