import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: FutureBuilder<List<Trip>>(
        future: api.getTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return const Center(child: Text('No trips planned yet.', style: TextStyle(color: AppTheme.textMuted)));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Upcoming trips
              _tripsList(trips.where((t) => t.status == 'upcoming').toList()),
              // Completed trips
              _tripsList(trips.where((t) => t.status == 'completed').toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _tripsList(List<Trip> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No trips in this category.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final trip = list[index];
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TripDetailsShell(trip: trip)),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(trip.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('₹${trip.optimizedCost.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.startDate.day} May - ${trip.endDate.day} May 2026 • ${trip.travelersCount} Travelers',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// Shell hosting Itinerary, Map, and Expenses tabs for a trip
class TripDetailsShell extends StatefulWidget {
  final Trip trip;
  const TripDetailsShell({super.key, required this.trip});

  @override
  State<TripDetailsShell> createState() => _TripDetailsShellState();
}

class _TripDetailsShellState extends State<TripDetailsShell> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.title),
        actions: [
          if (widget.trip.status == 'upcoming')
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.success),
              tooltip: 'Mark as Completed',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Complete Trip'),
                    content: const Text('Mark this trip as completed? It will move to your Travel History.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  final api = Provider.of<ApiService>(context, listen: false);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final success = await api.updateTripStatus(widget.trip.id, 'completed');
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Trip marked as completed!')),
                    );
                    navigator.pop(); // Go back to refresh list
                  }
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Itinerary'),
            Tab(text: 'Route Map'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TravelItineraryScreen(trip: widget.trip),
          TripRouteMapScreen(trip: widget.trip),
          ExpenseTrackerScreen(trip: widget.trip),
        ],
      ),
    );
  }
}

class TravelItineraryScreen extends StatelessWidget {
  final Trip trip;
  const TravelItineraryScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final days = trip.itinerary.keys.toList()..sort();

    if (days.isEmpty) {
      return const Center(child: Text('No itinerary activities.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final dayKey = days[index];
        final list = trip.itinerary[dayKey] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayKey,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            const Divider(color: AppTheme.primary),
            const SizedBox(height: 8),
            
            ...list.map((act) => _itineraryActivityRow(act)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _itineraryActivityRow(Activity act) {
    Color indicatorColor = AppTheme.primary;
    if (act.category == 'stay') indicatorColor = AppTheme.success;
    if (act.category == 'food') indicatorColor = AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: indicatorColor),
              ),
              Container(width: 2, height: 60, color: AppTheme.border),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(act.time, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    if (act.cost > 0)
                      Text('₹${act.cost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(act.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseTrackerScreen extends StatefulWidget {
  final Trip trip;
  const ExpenseTrackerScreen({super.key, required this.trip});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'food';
  List<Expense> _expensesList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final data = await api.getExpenses(widget.trip.id);
    if (mounted) {
      setState(() {
        _expensesList = data;
        _loading = false;
      });
    }
  }

  Future<void> _handleAddExpense() async {
    final title = _titleController.text.trim();
    final amountStr = _amountController.text.trim();
    if (title.isEmpty || amountStr.isEmpty) return;

    final api = Provider.of<ApiService>(context, listen: false);
    final expense = await api.addExpense(widget.trip.id, title, double.parse(amountStr), _category);
    
    if (expense != null) {
      _titleController.clear();
      _amountController.clear();
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalSpent = 0;
    Map<String, double> categoriesSum = {'stay': 0, 'transport': 0, 'food': 0, 'activities': 0, 'others': 0};

    for (var e in _expensesList) {
      totalSpent += e.amount;
      if (categoriesSum.containsKey(e.category)) {
        categoriesSum[e.category] = categoriesSum[e.category]! + e.amount;
      } else {
        categoriesSum['others'] = categoriesSum['others']! + e.amount;
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total spent card
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Total Spent', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text(
                      '₹${totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optimized Limit: ₹${widget.trip.optimizedCost.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Expenses Chart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // fl_chart Bar Chart representing categories
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: categoriesSum.values.fold(100.0, (prev, val) => val > prev ? val : prev) + 1000,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const labels = ['Stay', 'Trans', 'Food', 'Activ', 'Other'];
                          if (val.toInt() >= 0 && val.toInt() < labels.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(labels[val.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _barGroup(0, categoriesSum['stay']!, AppTheme.success),
                    _barGroup(1, categoriesSum['transport']!, AppTheme.primary),
                    _barGroup(2, categoriesSum['food']!, AppTheme.warning),
                    _barGroup(3, categoriesSum['activities']!, Colors.pinkAccent),
                    _barGroup(4, categoriesSum['others']!, Colors.blueGrey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Add new expense card form
            const Text('Log New Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title / Description'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Amount (INR)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            onChanged: (val) => setState(() => _category = val!),
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: const [
                              DropdownMenuItem(value: 'stay', child: Text('Stay')),
                              DropdownMenuItem(value: 'transport', child: Text('Transport')),
                              DropdownMenuItem(value: 'food', child: Text('Food')),
                              DropdownMenuItem(value: 'activities', child: Text('Activities')),
                              DropdownMenuItem(value: 'others', child: Text('Others')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _handleAddExpense,
                        child: const Text('Add Log'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text('History Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _expensesList.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final item = _expensesList[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.category.toUpperCase()),
                        trailing: Text('₹${item.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }
}

List<Activity> _enrichActivities(String destination, List<Activity> originalList) {
  if (originalList.isEmpty) return originalList;
  final dest = destination.toLowerCase();
  
  final goaCoords = [
    const ll.LatLng(15.2736, 73.9582),
    const ll.LatLng(15.5494, 73.7535),
    const ll.LatLng(15.5442, 73.7550),
    const ll.LatLng(15.5550, 73.7520),
    const ll.LatLng(15.4294, 73.7742),
    const ll.LatLng(15.5994, 73.7480),
    const ll.LatLng(15.4926, 73.7736)
  ];
  
  final manaliCoords = [
    const ll.LatLng(32.2276, 77.1873),
    const ll.LatLng(32.2530, 77.1850),
    const ll.LatLng(32.2450, 77.1860),
    const ll.LatLng(32.2500, 77.1900),
    const ll.LatLng(32.2630, 77.1880),
    const ll.LatLng(32.2520, 77.1840),
    const ll.LatLng(32.2700, 77.1800)
  ];

  final keralaCoords = [
    const ll.LatLng(9.9816, 76.2999),
    const ll.LatLng(9.4981, 76.3388),
    const ll.LatLng(9.5300, 76.3500),
    const ll.LatLng(9.5100, 76.3400),
    const ll.LatLng(9.5400, 76.3600),
    const ll.LatLng(9.5200, 76.3350),
    const ll.LatLng(9.4900, 76.3200)
  ];

  final dubaiCoords = [
    const ll.LatLng(25.2532, 55.3657),
    const ll.LatLng(25.2285, 55.3273),
    const ll.LatLng(25.1972, 55.2744),
    const ll.LatLng(25.2000, 55.2800),
    const ll.LatLng(25.2100, 55.2600),
    const ll.LatLng(25.1900, 55.2700),
    const ll.LatLng(25.1800, 55.2500)
  ];

  final shimlaCoords = [
    const ll.LatLng(31.1033, 77.1610),
    const ll.LatLng(31.1044, 77.1700),
    const ll.LatLng(31.1050, 77.1740),
    const ll.LatLng(31.1060, 77.1720),
    const ll.LatLng(31.1100, 77.1800),
    const ll.LatLng(31.1020, 77.1680),
    const ll.LatLng(31.1080, 77.1780)
  ];

  final jaipurCoords = [
    const ll.LatLng(26.9220, 75.7860),
    const ll.LatLng(26.9150, 75.8000),
    const ll.LatLng(26.9250, 75.8200),
    const ll.LatLng(26.9180, 75.8100),
    const ll.LatLng(26.9855, 75.8513),
    const ll.LatLng(26.9200, 75.7900),
    const ll.LatLng(26.9239, 75.8267)
  ];

  final lehCoords = [
    const ll.LatLng(34.1444, 77.5555),
    const ll.LatLng(34.1600, 77.5800),
    const ll.LatLng(34.1500, 77.6000),
    const ll.LatLng(34.1550, 77.5900),
    const ll.LatLng(34.1700, 77.6200),
    const ll.LatLng(34.1620, 77.5700),
    const ll.LatLng(34.1438, 77.5850)
  ];

  var defaultList = goaCoords;
  if (dest.contains('manali')) {
    defaultList = manaliCoords;
  } else if (dest.contains('kerala')) {
    defaultList = keralaCoords;
  } else if (dest.contains('dubai')) {
    defaultList = dubaiCoords;
  } else if (dest.contains('shimla')) {
    defaultList = shimlaCoords;
  } else if (dest.contains('jaipur')) {
    defaultList = jaipurCoords;
  } else if (dest.contains('leh') || dest.contains('ladakh')) {
    defaultList = lehCoords;
  }

  return List<Activity>.generate(originalList.length, (idx) {
    final act = originalList[idx];
    if (act.lat != 0.0 && act.lng != 0.0) {
      return act;
    }
    final fallback = defaultList[idx % defaultList.length];
    return Activity(
      time: act.time,
      title: act.title,
      description: act.description,
      cost: act.cost,
      category: act.category,
      lat: fallback.latitude,
      lng: fallback.longitude,
    );
  });
}

class TripRouteMapScreen extends StatefulWidget {
  final Trip trip;
  const TripRouteMapScreen({super.key, required this.trip});

  @override
  State<TripRouteMapScreen> createState() => _TripRouteMapScreenState();
}

class _TripRouteMapScreenState extends State<TripRouteMapScreen> {
  int _selectedActivityIndex = 0;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawActivities = <Activity>[];
    final days = widget.trip.itinerary.keys.toList()..sort();
    for (final d in days) {
      rawActivities.addAll(widget.trip.itinerary[d] ?? []);
    }

    final activities = _enrichActivities(widget.trip.destination, rawActivities);

    if (activities.isEmpty) {
      return const Center(child: Text('No activities to track.'));
    }

    final activeActivity = activities[_selectedActivityIndex];
    final activeLatLng = ll.LatLng(activeActivity.lat, activeActivity.lng);
    final routePoints = activities.map((a) => ll.LatLng(a.lat, a.lng)).toList();

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: activeLatLng,
                      initialZoom: 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.smarttravelplanner.app',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: AppTheme.primary,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: List.generate(activities.length, (idx) {
                          final act = activities[idx];
                          final isSelected = idx == _selectedActivityIndex;
                          final pinColor = isSelected ? Colors.redAccent : _getPinColor(act.category);

                          return Marker(
                            point: ll.LatLng(act.lat, act.lng),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedActivityIndex = idx;
                                });
                                _mapController.move(ll.LatLng(act.lat, act.lng), 13.5);
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                      ),
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.redAccent : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.location_on,
                                    color: pinColor,
                                    size: isSelected ? 34.0 : 28.0,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          widget.trip.destination,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(activeActivity.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activeActivity.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(activeActivity.category),
                      ),
                    ),
                  ),
                  Text(
                    activeActivity.time,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activeActivity.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                activeActivity.description,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.navigation_outlined, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Coords: ${activeActivity.lat.toStringAsFixed(4)}, ${activeActivity.lng.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  if (activeActivity.cost > 0)
                    Text(
                      '₹${activeActivity.cost.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectedActivityIndex > 0
                        ? () {
                            setState(() => _selectedActivityIndex--);
                            final prevAct = activities[_selectedActivityIndex];
                            _mapController.move(ll.LatLng(prevAct.lat, prevAct.lng), 12.0);
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('Prev'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    'Step ${_selectedActivityIndex + 1} of ${activities.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedActivityIndex < activities.length - 1
                        ? () {
                            setState(() => _selectedActivityIndex++);
                            final nextAct = activities[_selectedActivityIndex];
                            _mapController.move(ll.LatLng(nextAct.lat, nextAct.lng), 12.0);
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPinColor(String cat) {
    if (cat == 'stay') return AppTheme.success;
    if (cat == 'transport') return AppTheme.primary;
    if (cat == 'food') return AppTheme.warning;
    return Colors.pinkAccent;
  }

  Color _getCategoryColor(String cat) {
    if (cat == 'stay') return AppTheme.success;
    if (cat == 'transport') return AppTheme.primary;
    if (cat == 'food') return AppTheme.warning;
    return Colors.pinkAccent;
  }
}
