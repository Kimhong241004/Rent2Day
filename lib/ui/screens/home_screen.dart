import 'package:flutter/material.dart';
import '../../data/json_storage_service.dart';
import 'rooms_screen.dart';
import 'search_screen.dart';
import 'tenants_screen.dart';
import 'payments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation State
  int _selectedIndex = 0;
  
  // Storage service
  final JsonStorageService _storageService = JsonStorageService();
  bool _isInitialized = false; // Set to false until storage is initialized

  // Data variables
  int totalRooms = 0;
  int availableRooms = 0;
  int occupiedRooms = 0;
  int maintenanceRooms = 0;
  double totalRentCollected = 0.0;
  double thisMonthRent = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }
  
  Future<void> _initializeAndLoad() async {
    try {
      await _storageService.init();
      debugPrint('Storage initialized successfully');
      await _loadDashboardData();
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Continue anyway - storage might not work on all platforms
    } finally {
      // Always show UI
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh dashboard data only if initialized
    if (_isInitialized) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!_isInitialized) return; // Don't load if not initialized
    
    try {
      final rooms = await _storageService.getRooms();
      final payments = await _storageService.getPayments();

      int available = 0;
      int occupied = 0;
      int maintenance = 0;

      for (var room in rooms) {
        if (room.status == 'Available') {
          available++;
        } else if (room.status == 'Occupied') {
          occupied++;
        } else if (room.status == 'Maintenance') {
          maintenance++;
        }
      }

      // Calculate total rent collected (all payments that are paid)
      double totalCollected = 0.0;
      double thisMonth = 0.0;
      final now = DateTime.now();

      for (var payment in payments) {
        if (payment.isPaid) {
          totalCollected += payment.amount;
          // Check if payment is from this month
          if (payment.date.year == now.year && payment.date.month == now.month) {
            thisMonth += payment.amount;
          }
        }
      }

      setState(() {
        totalRooms = rooms.length;
        availableRooms = available;
        occupiedRooms = occupied;
        maintenanceRooms = maintenance;
        totalRentCollected = totalCollected;
        thisMonthRent = thisMonth;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rent Manager',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: !_isInitialized
        ? const Center(child: CircularProgressIndicator())
        : _selectedIndex == 0 
          ? _buildDashboard() 
          : _selectedIndex == 1
            ? SearchScreen(storageService: _storageService)
            : _selectedIndex == 2
              ? RoomsScreen(storageService: _storageService)
              : _selectedIndex == 3
                ? TenantsScreen(storageService: _storageService)
                : PaymentsScreen(storageService: _storageService),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF56CCF2),
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard, "Dashboard"),
            _buildNavItem(1, Icons.search, "Search"),
            _buildNavItem(2, Icons.meeting_room, "Rooms"),
            _buildNavItem(3, Icons.people, "Tenants"),
            _buildNavItem(4, Icons.payments, "Payments"),
          ],
        ),
      ),
    );
  }

  // Your original Dashboard UI
  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back to rent manager',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Friday December 12/2025',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Room Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(child: _buildStatCard(icon: Icons.apartment, value: totalRooms.toString(), label: 'Total Rooms', iconColor: const Color(0xFF2196F3))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(icon: Icons.check_circle, value: availableRooms.toString(), label: 'Available', iconColor: const Color(0xFF4CAF50))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(icon: Icons.people, value: occupiedRooms.toString(), label: 'Occupied', iconColor: const Color(0xFFFF9800))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(icon: Icons.build, value: maintenanceRooms.toString(), label: 'Maintenance', iconColor: const Color(0xFFF44336))),
              ],
            ),
            const SizedBox(height: 24),
            // Financial Overview Widget
            const Text(
              'Financial Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Rent Collected',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${totalRentCollected.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'This Month',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${thisMonthRent.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // (Moved up)
            // Remove duplicate Financial Overview section and fix commas
            // ...existing widgets...
          ],

        ),
      ),
    );
  }

  // Helper for Nav Items
  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          // Refresh dashboard data when returning to it
          if (index == 0) {
            _loadDashboardData();
          }
        },
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedOpacity(
            opacity: isSelected ? 1.0 : 0.7,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for Stat Cards
  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color iconColor}) {
    // Determine color for value based on label
    Color valueColor;
    switch (label) {
      case 'Total Rooms':
        valueColor = const Color(0xFF2196F3); // blue
        break;
      case 'Available':
        valueColor = const Color(0xFF4CAF50); // green
        break;
      case 'Occupied':
        valueColor = const Color(0xFFFF9800); // orange
        break;
      case 'Maintenance':
        valueColor = const Color(0xFFF44336); // red
        break;
      default:
        valueColor = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

}