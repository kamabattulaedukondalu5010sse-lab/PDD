import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'planner_screens.dart';
import 'trip_detail_screens.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeDashboard(),
    const SearchDestinationScreen(),
    const MyTripsScreen(), // Reused from trip details
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel_outlined), activeIcon: Icon(Icons.card_travel), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), activeIcon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  List<Destination> _destinations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final data = await api.getDestinations();
    if (mounted) {
      setState(() {
        _destinations = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ApiService>(context).currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User header greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.name.split(' ')[0] ?? 'Traveller'}! 👋',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const Text(
                        'Plan smart, travel better',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(user?.avatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search field shortcut
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchDestinationScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppTheme.textMuted),
                      SizedBox(width: 12),
                      Text('Where do you want to go?', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Action grid cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _actionCard(Icons.map_outlined, 'Plan a Trip', const Color(0xFFEFF6FF), AppTheme.primary, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripPlannerScreen()));
                  }),
                  _actionCard(Icons.auto_awesome_outlined, 'AI Suggestions', const Color(0xFFF0FDF4), AppTheme.success, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSuggestionsScreen()));
                  }),
                  _actionCard(Icons.location_on_outlined, 'Top Destinations', const Color(0xFFFEF3C7), AppTheme.warning, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TopDestinationsScreen()));
                  }),
                  _actionCard(Icons.donut_large, 'Budget Planner', const Color(0xFFFDF2F8), Colors.pinkAccent, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetToolScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 28),

              // Popular Destinations horizontal list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popular Destinations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchDestinationScreen()));
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: _loading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _destinations.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final dest = _destinations[index];
                          return _destinationCard(dest);
                        },
                      ),
              ),
              const SizedBox(height: 28),

              // Best Deals Banner card
              const Text('Best Deals for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              _bestDealsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 28),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationCard(Destination dest) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => TripPlannerScreen(initialDestination: dest.name)));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(image: NetworkImage(dest.imageUrl), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                dest.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star, color: AppTheme.warning, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${dest.rating}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bestDealsCard() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const TripPlannerScreen(initialDestination: 'Goa'),
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=150',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('30% OFF', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Goa Trip Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('3 Nights / 4 Days • Flight + Hotel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text('₹6,999', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                        SizedBox(width: 6),
                        Text('₹9,999', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({super.key});

  @override
  State<SearchDestinationScreen> createState() => _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Destination> _allDestinations = [];
  List<Destination> _filteredDestinations = [];
  bool _loading = true;

  // Filter criteria
  String _selectedCategory = 'All';
  double _minRating = 4.0;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final data = await api.getDestinations();
    if (mounted) {
      setState(() {
        _allDestinations = data;
        _applyFilters();
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDestinations = _allDestinations.where((dest) {
        final matchesName = dest.name.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'All' || dest.category == _selectedCategory;
        final matchesRating = dest.rating >= _minRating;
        return matchesName && matchesCategory && matchesRating;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final categories = ['All', 'Beach', 'Mountain', 'Nature', 'Luxury', 'Heritage', 'Adventure'];
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = 'All';
                            _minRating = 4.0;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            setModalState(() {
                              _selectedCategory = cat;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.warning, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _minRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _minRating,
                    min: 4.0,
                    max: 5.0,
                    divisions: 10,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      setModalState(() {
                        _minRating = val;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> popularSearches = [
      {'name': 'Goa', 'rating': '4.8'},
      {'name': 'Manali', 'rating': '4.7'},
      {'name': 'Kerala', 'rating': '4.6'},
      {'name': 'Dubai', 'rating': '4.9'},
      {'name': 'Thailand', 'rating': '4.5'},
      {'name': 'Bali', 'rating': '4.7'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Destination'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search destinations...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: _showFilterBottomSheet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Popular Searches',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: popularSearches.map((item) {
                      return ActionChip(
                        label: Text('${item['name']} (★ ${item['rating']})'),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.border),
                        onPressed: () {
                          setState(() {
                            _searchController.text = item['name']!;
                          });
                          _applyFilters();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top Destinations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      if (_searchController.text.isNotEmpty || _selectedCategory != 'All' || _minRating > 4.0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedCategory = 'All';
                              _minRating = 4.0;
                            });
                            _applyFilters();
                          },
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _filteredDestinations.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text('No matching destinations found.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredDestinations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final dest = _filteredDestinations[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  dest.imageUrl.isNotEmpty ? dest.imageUrl : 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=100',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              title: Text(dest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.star, color: AppTheme.warning, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dest.rating} • ${dest.category}',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => TripPlannerScreen(initialDestination: dest.name),
                                ));
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}

class AiSuggestionsScreen extends StatelessWidget {
  const AiSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      {
        'title': 'High Altitude Leh Ladakh Expedition',
        'desc': 'AI recommended adventure route. Includes route optimization, high-altitude camps, and monastery stops.',
        'destination': 'Leh Ladakh',
        'difficulty': 'Hard',
        'type': 'Adventure',
        'rating': '4.9',
      },
      {
        'title': 'Scenic Kerala Backwaters & Nature Trail',
        'desc': 'AI recommended leisure route. Includes houseboat booking recommendations and spa stays.',
        'destination': 'Kerala',
        'difficulty': 'Easy',
        'type': 'Nature',
        'rating': '4.8',
      },
      {
        'title': 'Heritage & Palace Tour of Jaipur',
        'desc': 'AI recommended cultural route. Includes visits to Amber Fort, City Palace, and local bazaars.',
        'destination': 'Jaipur',
        'difficulty': 'Medium',
        'type': 'Heritage',
        'rating': '4.7',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AI Suggestions')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
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
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['type']!.toUpperCase(),
                          style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.warning, size: 14),
                          const SizedBox(width: 4),
                          Text(item['rating']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title']!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['desc']!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Destination: ${item['destination']}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TripPlannerScreen(initialDestination: item['destination']),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Plan Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TopDestinationsScreen extends StatefulWidget {
  const TopDestinationsScreen({super.key});

  @override
  State<TopDestinationsScreen> createState() => _TopDestinationsScreenState();
}

class _TopDestinationsScreenState extends State<TopDestinationsScreen> {
  List<Destination> _destinations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final data = await api.getDestinations();
    if (mounted) {
      setState(() {
        _destinations = data.where((d) => d.rating >= 4.7).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Rated Destinations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final dest = _destinations[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => TripPlannerScreen(initialDestination: dest.name),
                    ));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(dest.imageUrl.isNotEmpty ? dest.imageUrl : 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            dest.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: AppTheme.warning, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dest.rating}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                dest.category,
                                style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class BudgetToolScreen extends StatefulWidget {
  const BudgetToolScreen({super.key});

  @override
  State<BudgetToolScreen> createState() => _BudgetToolScreenState();
}

class _BudgetToolScreenState extends State<BudgetToolScreen> {
  String _destination = 'Goa';
  int _travelers = 2;
  double _budget = 25000;
  double? _estimatedCost;

  final List<String> _options = ['Goa', 'Manali', 'Kerala', 'Dubai', 'Shimla', 'Jaipur', 'Leh Ladakh'];

  void _calculate() {
    double base = 8000;
    if (_destination == 'Dubai') base = 35000;
    if (_destination == 'Leh Ladakh') base = 15000;
    if (_destination == 'Kerala') base = 10000;

    setState(() {
      _estimatedCost = base * _travelers * 0.85;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estimate Trip Costs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calculate base costs and see recommendations for your destinations.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),
            const Text('Select Destination', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _destination,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined)),
              items: _options.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _destination = val);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text('Number of Travelers', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _travelers,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.people_outline)),
              items: [1, 2, 3, 4, 5, 6].map((int val) {
                return DropdownMenuItem<int>(value: val, child: Text('$val Travelers'));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _travelers = val);
                }
              },
            ),
            const SizedBox(height: 20),
            const Text('Your Maximum Budget (INR)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              keyboardType: TextInputType.number,
              initialValue: _budget.toStringAsFixed(0),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.currency_rupee)),
              onChanged: (val) {
                final parsed = double.tryParse(val);
                if (parsed != null) {
                  _budget = parsed;
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate Estimate'),
              ),
            ),
            if (_estimatedCost != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ESTIMATED COSTsuggested by AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_estimatedCost!.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        Text(
                          _estimatedCost! <= _budget ? 'Under Budget' : 'Over Budget',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _estimatedCost! <= _budget ? AppTheme.success : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This includes estimated standard hotel stay and transport route optimizations.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TripPlannerScreen(initialDestination: _destination),
                          ));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        child: const Text('Plan This Optimized Trip'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = [
      {'title': 'Booking Confirmed', 'body': 'Your trip to Goa is confirmed. Click to download details.', 'time': '2 hrs ago', 'icon': Icons.check_circle_outline, 'color': AppTheme.success},
      {'title': 'Price Drop Alert', 'body': 'Flight prices dropped for Dubai by 15%.', 'time': '1 day ago', 'icon': Icons.trending_down, 'color': AppTheme.primary},
      {'title': 'Weather Update', 'body': 'Goa is sunny and clear for travel on 20 May.', 'time': '2 days ago', 'icon': Icons.wb_sunny_outlined, 'color': AppTheme.warning},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(color: AppTheme.border),
        itemBuilder: (context, index) {
          final item = list[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: (item['color'] as Color).withOpacity(0.1),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color),
            ),
            title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['body'] as String),
            trailing: Text(item['time'] as String, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ApiService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user?.avatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200'),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'John Doe',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? 'john@example.com',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            
            _profileOption(Icons.person_outline, 'Personal Information', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalInformationScreen()));
            }),
            _profileOption(Icons.description_outlined, 'My Documents', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyDocumentsScreen()));
            }),
            _profileOption(Icons.settings_outlined, 'Settings', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _profileOption(Icons.help_outline, 'Help & Support', () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            }),
            
            const SizedBox(height: 24),
            _profileOption(Icons.logout, 'Logout', () {
              Provider.of<ApiService>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            }, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _profileOption(IconData icon, String label, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: isLogout ? Colors.redAccent : AppTheme.textPrimary),
      title: Text(
        label,
        style: TextStyle(
          color: isLogout ? Colors.redAccent : AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: isLogout ? null : const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  String _currency = 'INR (₹)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
            activeColor: AppTheme.primary,
          ),
          SwitchListTile(
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
            activeColor: AppTheme.primary,
          ),
          ListTile(
            title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Text('English', style: TextStyle(color: AppTheme.textSecondary)),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(_currency, style: const TextStyle(color: AppTheme.textSecondary)),
            onTap: () {
              // Toggle currency display
              setState(() {
                _currency = _currency.contains('INR') ? 'USD (\$)' : 'INR (₹)';
              });
            },
          ),
          ListTile(
            title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
          ListTile(
            title: const Text('About App', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiService>(context, listen: false);
    final user = api.currentUser;
    _nameController = TextEditingController(text: user?.name ?? 'John Doe');
    _emailController = TextEditingController(text: user?.email ?? 'john@example.com');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final api = Provider.of<ApiService>(context, listen: false);
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final success = await api.updateProfile(
                      _nameController.text,
                      _emailController.text,
                      _phoneController.text,
                    );
                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Profile information updated successfully!')),
                      );
                      navigator.pop();
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Failed to update profile.')),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  final List<Map<String, String>> _documents = [
    {'title': 'Passport Copy', 'type': 'PDF', 'size': '1.2 MB', 'date': '2026-08-01'},
    {'title': 'Visa Confirmation - Dubai', 'type': 'PDF', 'size': '540 KB', 'date': '2026-08-05'},
    {'title': 'Flight Boarding Pass', 'type': 'IMAGE', 'size': '820 KB', 'date': '2026-08-08'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            onPressed: () {
              setState(() {
                _documents.add({
                  'title': 'New Travel Voucher',
                  'type': 'PDF',
                  'size': '450 KB',
                  'date': DateTime.now().toString().split(' ')[0],
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulated document upload successful!')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  doc['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.image,
                  color: AppTheme.primary,
                ),
              ),
              title: Text(doc['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${doc['size']} • Uploaded: ${doc['date']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    _documents.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document deleted.')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _supportCard(
            context,
            Icons.chat_bubble_outline,
            'Live Chat Support',
            'Chat with our assistant for real-time resolutions.',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connecting to support assistant...')),
              );
            },
          ),
          _supportCard(
            context,
            Icons.email_outlined,
            'Email Support',
            'Drop us a line at support@smarttravelplanner.com',
            () {},
          ),
          const SizedBox(height: 28),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _faqItem(
            'How does cost optimization work?',
            'Our AI suggestion engine compares multiple transport methods, local package listings, and hotel options to bundle a highly optimized itinerary matching your budget parameter.',
          ),
          _faqItem(
            'How do I mark a trip as completed?',
            'Go to Itinerary Details and click the Checkmark Circle icon in the Appbar actions list. The trip will move to your Travel History.',
          ),
          _faqItem(
            'Can I access travel data offline?',
            'Yes! The smart planner is fully offline fallback integrated, enabling access to cached itineraries, mock seeds, and document views even when you are disconnected.',
          ),
        ],
      ),
    );
  }

  Widget _supportCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            answer,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
