import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Destination {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final double costFactor;
  final String category;
  final double lat;
  final double lng;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.costFactor,
    required this.category,
    required this.lat,
    required this.lng,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
      costFactor: (json['costFactor'] ?? 1.0).toDouble(),
      category: json['category'] ?? 'Beach',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}

class Activity {
  final String time;
  final String title;
  final String description;
  final double cost;
  final String category;
  final double lat;
  final double lng;

  Activity({
    required this.time,
    required this.title,
    required this.description,
    required this.cost,
    required this.category,
    required this.lat,
    required this.lng,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      category: json['category'] ?? 'activities',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }
}

class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int travelersCount;
  final double budget;
  final double optimizedCost;
  final String transportType;
  final String hotelName;
  final Map<String, List<Activity>> itinerary;
  final String status;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.travelersCount,
    required this.budget,
    required this.optimizedCost,
    required this.transportType,
    required this.hotelName,
    required this.itinerary,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final itineraryJson = json['itinerary'] as Map<String, dynamic>? ?? {};
    final parsedItinerary = <String, List<Activity>>{};
    
    itineraryJson.forEach((day, activitiesList) {
      if (activitiesList is List) {
        parsedItinerary[day] = activitiesList
            .map((act) => Activity.fromJson(act as Map<String, dynamic>))
            .toList();
      }
    });

    return Trip(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      travelersCount: json['travelersCount'] ?? 1,
      budget: (json['budget'] ?? 0).toDouble(),
      optimizedCost: (json['optimizedCost'] ?? 0).toDouble(),
      transportType: json['transportType'] ?? 'Train',
      hotelName: json['hotelName'] ?? '',
      itinerary: parsedItinerary,
      status: json['status'] ?? 'upcoming',
    );
  }
}

class Booking {
  final String id;
  final String tripId;
  final String type;
  final String name;
  final String details;
  final double cost;
  final String bookingIdString;
  final String status;

  Booking({
    required this.id,
    required this.tripId,
    required this.type,
    required this.name,
    required this.details,
    required this.cost,
    required this.bookingIdString,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? '',
      tripId: json['tripId'] ?? '',
      type: json['type'] ?? 'hotel',
      name: json['name'] ?? '',
      details: json['details'] ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      bookingIdString: json['bookingIdString'] ?? '',
      status: json['status'] ?? 'confirmed',
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'others',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}
