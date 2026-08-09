import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class HotelBookingScreen extends StatefulWidget {
  final Trip trip;
  const HotelBookingScreen({super.key, required this.trip});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  int _selectedRoomIndex = 0; // 0: Deluxe, 1: Sea View

  @override
  Widget build(BuildContext context) {
    final roomTypes = [
      {'name': 'Deluxe Room', 'price': 4999.0, 'desc': 'Standard king bed, high speed Wi-Fi, breakfast included.'},
      {'name': 'Sea View Room', 'price': 8499.0, 'desc': 'Ocean front view balcony, mini bar access, luxury bathing amenities.'}
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Booking')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Beach Resort Goa',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.warning, size: 18),
                          const SizedBox(width: 4),
                          Text('4.7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      )
                    ],
                  ),
                  const Text('Calangute Beach Road, North Goa', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  const Text(
                    'Set along the sandy shores of Calangute Beach, this premium property offers spectacular dining options, swimming pools, spa facilities, and immediate beach access for a tranquil escape.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  const Text('Select Room Option', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roomTypes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final room = roomTypes[index];
                      final isSelected = _selectedRoomIndex == index;
                      return InkWell(
                        onTap: () => setState(() => _selectedRoomIndex = index),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: isSelected ? 2 : 1),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected ? AppTheme.primary.withOpacity(0.01) : Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(room['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('₹${(room['price'] as double).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(room['desc'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final chosenRoom = roomTypes[_selectedRoomIndex];
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              trip: widget.trip,
                              type: 'hotel',
                              name: widget.trip.hotelName.isNotEmpty ? widget.trip.hotelName : 'Beach Resort Goa',
                              details: chosenRoom['name'] as String,
                              cost: chosenRoom['price'] as double,
                            ),
                          ),
                        );
                      },
                      child: const Text('Book Room Now'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final Trip trip;
  final String type; // 'hotel' or 'transport'
  final String name; // Name of hotel or flight/train
  final String details;
  final double cost;

  const PaymentScreen({
    super.key,
    required this.trip,
    required this.type,
    required this.name,
    required this.details,
    required this.cost,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0; // 0: UPI, 1: Card, 2: NetBanking
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    
    final api = Provider.of<ApiService>(context, listen: false);
    final booking = await api.createBooking(
      widget.trip.id,
      widget.type,
      widget.name,
      widget.details,
      widget.cost,
    );
    
    setState(() => _isLoading = false);

    if (booking != null && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            trip: widget.trip,
            type: widget.type,
            name: widget.name,
            details: widget.details,
            cost: widget.cost,
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed or booking could not be saved.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = widget.cost * 1.05; // 5% GST/Fee baseline

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Checkout Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _billRow(widget.type == 'hotel' ? 'Hotel stay (${widget.details})' : 'Transit ticket (${widget.details})', '₹${widget.cost.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    _billRow('Convenience fee & GST', '₹${(widget.cost * 0.05).toStringAsFixed(0)}'),
                    const Divider(height: 24),
                    _billRow('Total Amount', '₹${totalAmount.toStringAsFixed(0)}', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _paymentRadioTile(0, 'UPI (GPay / PhonePe)', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 12),
            _paymentRadioTile(1, 'Credit / Debit Card', Icons.credit_card_outlined),
            const SizedBox(height: 12),
            _paymentRadioTile(2, 'Net Banking', Icons.account_balance_outlined),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePayment,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Pay ₹${totalAmount.toStringAsFixed(0)}'),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppTheme.textMuted),
                  SizedBox(width: 4),
                  Text('100% Secure Payments powered by Razorpay', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14)),
        Text(price, style: TextStyle(color: isTotal ? AppTheme.primary : AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 14)),
      ],
    );
  }

  Widget _paymentRadioTile(int index, String label, IconData icon) {
    final isSelected = _selectedMethod == index;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primary.withOpacity(0.01) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
            Radio<int>(
              value: index,
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
              activeColor: AppTheme.primary,
            )
          ],
        ),
      ),
    );
  }
}

class BookingConfirmationScreen extends StatelessWidget {
  final Trip trip;
  final String type;
  final String name;
  final String details;
  final double cost;

  const BookingConfirmationScreen({
    super.key,
    required this.trip,
    required this.type,
    required this.name,
    required this.details,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final bookingId = 'TRP${100000000 + (name.hashCode % 900000000).abs()}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Checkmark Circle
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const Text('Your trip resource is successfully booked.', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 36),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _rowDetails('Booking ID', bookingId),
                      const SizedBox(height: 8),
                      _rowDetails('Destination', trip.destination),
                      const SizedBox(height: 8),
                      _rowDetails(type == 'hotel' ? 'Stay Reservation' : 'Transit Ticket', name),
                      const SizedBox(height: 8),
                      _rowDetails('Tier/Class', details),
                      const SizedBox(height: 8),
                      _rowDetails('Dates', '${trip.startDate.day} May - ${trip.endDate.day} May 2026'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to DashboardLayout
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  },
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: const Text('Download E-Ticket & Receipt', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowDetails(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class TransportBookingScreen extends StatefulWidget {
  final Trip trip;
  const TransportBookingScreen({super.key, required this.trip});

  @override
  State<TransportBookingScreen> createState() => _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  int _selectedOptionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isFlight = widget.trip.budget > 30000;
    final transportOptions = isFlight 
        ? [
            {'name': 'Indigo Air AI-302', 'class': 'Economy Class', 'price': widget.trip.optimizedCost * 0.45, 'desc': 'Standard fare, 15kg check-in bag, seat assignment included.'},
            {'name': 'Air India AI-102', 'class': 'Business Class', 'price': widget.trip.optimizedCost * 0.85, 'desc': 'Lounge access, priority boarding, complimentary gourmet meals.'}
          ]
        : [
            {'name': 'Konkan Express Train', 'class': 'AC 3 Tier (3AC)', 'price': widget.trip.optimizedCost * 0.45, 'desc': 'Sleeper berths with AC comfort, pillows & linen provided.'},
            {'name': 'Konkan Express Train', 'class': 'AC 2 Tier (2AC)', 'price': widget.trip.optimizedCost * 0.65, 'desc': 'Spacious 4-berth compartments, privacy curtains, wider berths.'}
          ];

    return Scaffold(
      appBar: AppBar(title: Text(isFlight ? 'Flight Booking' : 'Train Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(isFlight ? Icons.flight_takeoff : Icons.train, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transit to ${widget.trip.destination}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${widget.trip.travelersCount} Travelers • Departure: ${widget.trip.startDate.day} May 2026', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Ticket Option', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transportOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final opt = transportOptions[index];
                final isSelected = _selectedOptionIndex == index;
                return InkWell(
                  onTap: () => setState(() => _selectedOptionIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? AppTheme.primary.withOpacity(0.01) : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('${opt['name']} (${opt['class']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                            Text('₹${(opt['price'] as double).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(opt['desc'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final chosen = transportOptions[_selectedOptionIndex];
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        trip: widget.trip,
                        type: 'transport',
                        name: chosen['name'] as String,
                        details: chosen['class'] as String,
                        cost: chosen['price'] as double,
                      ),
                    ),
                  );
                },
                child: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: FutureBuilder<List<Booking>>(
        future: api.getBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_online_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('No bookings found.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text(
                      'Any reservations you book for hotel stay or transit ticket will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = list[index];
              final isHotel = booking.type == 'hotel';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isHotel ? Colors.green.withOpacity(0.12) : AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.type.toUpperCase(),
                              style: TextStyle(
                                color: isHotel ? Colors.green : AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(booking.bookingIdString, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(booking.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(booking.details, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${booking.cost.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                              SizedBox(width: 4),
                              Text('Confirmed', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
