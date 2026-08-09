import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'booking_screens.dart';

class TripPlannerScreen extends StatefulWidget {
  final String? initialDestination;
  const TripPlannerScreen({super.key, this.initialDestination});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final _fromController = TextEditingController(text: 'Mumbai');
  final _toController = TextEditingController(text: 'Goa');
  final _travelersController = TextEditingController(text: '2');
  final _budgetController = TextEditingController(text: '25000');
  DateTime _startDate = DateTime(2026, 5, 20);
  DateTime _endDate = DateTime(2026, 5, 25);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      _toController.text = widget.initialDestination!;
    }
  }

  Future<void> _handleOptimize() async {
    final destination = _toController.text.trim();
    final budgetStr = _budgetController.text.trim();
    final travelersStr = _travelersController.text.trim();

    if (destination.isEmpty || budgetStr.isEmpty || travelersStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all form fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final api = Provider.of<ApiService>(context, listen: false);
    final travelers = int.parse(travelersStr);
    final budget = double.parse(budgetStr);

    final trip = await api.createTrip(destination, _startDate, _endDate, travelers, budget);

    setState(() => _isLoading = false);

    if (trip != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BudgetPlannerScreen(trip: trip),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Optimization failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Your Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Planner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const Text('Enter travel details to start budget-optimization.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            
            TextField(
              controller: _fromController,
              decoration: const InputDecoration(
                labelText: 'From Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _toController,
              decoration: const InputDecoration(
                labelText: 'To Destination',
                prefixIcon: Icon(Icons.flight_land),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date Picker Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Departure'),
                      child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _endDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Return'),
                      child: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _travelersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Travelers',
                prefixIcon: Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Budget (INR)',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleOptimize,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Optimize Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetPlannerScreen extends StatelessWidget {
  final Trip trip;
  const BudgetPlannerScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final savings = trip.budget - trip.optimizedCost;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Savings header banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF1E3A8A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Budget', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '₹${trip.budget.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Optimized Cost', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('₹${trip.optimizedCost.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Smart Savings', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('₹${savings.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('Cost Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // fl_chart Donut
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(color: AppTheme.primary, value: 40, title: '40%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          PieChartSectionData(color: AppTheme.success, value: 30, title: '30%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          PieChartSectionData(color: AppTheme.warning, value: 15, title: '15%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          PieChartSectionData(color: Colors.pinkAccent, value: 10, title: '10%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          PieChartSectionData(color: Colors.blueGrey, value: 5, title: '5%', radius: 25, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(color: AppTheme.primary, text: 'Transport (40%)'),
                        _LegendItem(color: AppTheme.success, text: 'Stay (30%)'),
                        _LegendItem(color: AppTheme.warning, text: 'Food (15%)'),
                        _LegendItem(color: Colors.pinkAccent, text: 'Activities (10%)'),
                        _LegendItem(color: Colors.blueGrey, text: 'Others (5%)'),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Tip widget
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppTheme.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Book early to save 15% more on train routes and flights.',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AIRecommendationsScreen(trip: trip),
                    ),
                  );
                },
                child: const Text('View AI Recommendations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class AIRecommendationsScreen extends StatelessWidget {
  final Trip trip;
  const AIRecommendationsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Recommendations')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Recommendation', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Best Time to Visit Goa is May',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Perfect weather, sunny skies, and lower booking costs.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Recommended For You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _recommendCard(
              'Stay at Beach Resort',
              '₹4,999 / Night',
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=150',
              'Deluxe Room option with breakfast included.',
              4.7,
            ),
            const SizedBox(height: 16),
            _recommendCard(
              'Scuba Diving at Grand Island',
              '₹2,500 / Person',
              'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=150',
              'Explore reefs with professional instructions.',
              4.8,
            ),
            const SizedBox(height: 16),
            _recommendCard(
              'Dudhsagar Waterfalls Tour',
              '₹1,200 / Person',
              'https://images.unsplash.com/photo-1602216056096-3c40cc0c9944?w=150',
              'Full day tour with guide and lunch box.',
              4.6,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RouteOptimizationScreen(trip: trip),
                    ),
                  );
                },
                child: const Text('View Route Optimization'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendCard(String name, String price, String img, String desc, double rate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(img, width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      Text(price, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.warning, size: 14),
                      const SizedBox(width: 4),
                      Text('$rate', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteOptimizationScreen extends StatelessWidget {
  final Trip trip;
  const RouteOptimizationScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Optimization')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Best Route Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Text('Mumbai ➔ Goa routes comparison', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),

            _routeOptionCard(
              'By Train (Konkan Express)',
              '8h 45m • ₹2,500',
              'Train is the most cost-effective and comfortable option.',
              true, // Recommeded
              context,
            ),
            const SizedBox(height: 16),
            _routeOptionCard(
              'By Bus (Volvo Sleeper)',
              '12h 30m • ₹1,800',
              'Direct highway routes. Sleeper slots.',
              false,
              context,
            ),
            const SizedBox(height: 16),
            _routeOptionCard(
              'By Flight (Indigo)',
              '1h 10m • ₹6,200',
              'Fastest journey but 3x more expensive than train.',
              false,
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeOptionCard(String mode, String details, String description, bool recommended, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(mode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (recommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Recommended', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(details, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HotelBookingScreen(trip: trip),
                    ),
                  );
                },
                child: const Text('Select Option', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
