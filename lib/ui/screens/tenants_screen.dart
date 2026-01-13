import 'package:flutter/material.dart';
import '../../models/tenant.dart';
import '../../data/json_storage_service.dart';
import 'add_tenant_screen.dart';
import 'book_tenant_screen.dart';
import 'tenant_details_screen.dart';

class TenantsScreen extends StatefulWidget {
  final JsonStorageService storageService;
  const TenantsScreen({Key? key, required this.storageService}) : super(key: key);

  @override
  _TenantsScreenState createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Tenant>> _tenantsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTenants();
  }

  void _loadTenants() {
    _tenantsFuture = widget.storageService.getTenants();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTenants(); // Refresh when returning to this screen
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // TabBar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF56CCF2),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF56CCF2),
              tabs: const [
                Tab(text: 'Tenants'),
                Tab(text: 'Booking Room'),
              ],
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveTenants(),
                  _buildAllTenants(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (_tabController.index == 0) {
              // Tenants tab - open AddTenantScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTenantScreen(
                    storageService: widget.storageService,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  setState(() {
                    _loadTenants();
                  });
                }
              });
            } else {
              // Booking Room tab - open BookTenantScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookTenantScreen(
                    storageService: widget.storageService,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  setState(() {
                    _loadTenants();
                  });
                }
              });
            }
          },
          child: const Icon(Icons.add, color: Color(0xFF56CCF2), size: 40),
        ),
      ),
    );
  }

  Widget _buildActiveTenants() {
    return FutureBuilder<List<Tenant>>(
      future: _tenantsFuture,
      builder: (context, tenantSnapshot) {
        if (!tenantSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Tenant> tenants = tenantSnapshot.data ?? [];
        
        // Filter tenants with past or current move-in date (already renting)
        final now = DateTime.now();
        final currentTenants = tenants.where((t) {
          return t.moveInDate.isBefore(now) || 
                 (t.moveInDate.year == now.year && 
                  t.moveInDate.month == now.month && 
                  t.moveInDate.day == now.day);
        }).toList();

        if (currentTenants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active tenants',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Fetch rooms to get floor info
        return FutureBuilder<List>(
          future: widget.storageService.getRooms(),
          builder: (context, roomSnapshot) {
            final rooms = roomSnapshot.data ?? [];

            return ListView.builder(
              itemCount: currentTenants.length,
              itemBuilder: (context, index) {
                final tenant = currentTenants[index];
                // Find the room for this tenant to get floor
                dynamic room;
                try {
                  room = rooms.firstWhere(
                    (r) => r.roomNumber == tenant.assignedRoom,
                  );
                } catch (e) {
                  room = null;
                }
                final floor = room?.floor ?? 'N/A';

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(tenant.name[0]),
                  ),
                  title: Text(tenant.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      SizedBox(
                        height: 20,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(tenant.phone, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.meeting_room, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Room ${tenant.assignedRoom}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.layers, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Floor $floor', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TenantDetailsScreen(
                          storageService: widget.storageService,
                          tenantId: tenant.id,
                        ),
                      ),
                    ).then((result) {
                      // If tenant was edited, refresh the data
                      if (result == true) {
                        setState(() {
                          _loadTenants();
                        });
                      }
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAllTenants() {
    return FutureBuilder<List<Tenant>>(
      future: _tenantsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Tenant> tenants = snapshot.data ?? [];
        
        // Filter tenants with future move-in date (booked tenants)
        final now = DateTime.now();
        final bookedTenants = tenants.where((t) {
          return t.moveInDate.isAfter(now.add(Duration(days: 1))) || 
                 (t.moveInDate.year == now.year && 
                  t.moveInDate.month == now.month && 
                  t.moveInDate.day > now.day) ||
                 (t.moveInDate.year == now.year && 
                  t.moveInDate.month > now.month) ||
                 t.moveInDate.year > now.year;
        }).toList();

        if (bookedTenants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No bookings yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: bookedTenants.length,
          itemBuilder: (context, index) {
            final tenant = bookedTenants[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(tenant.name[0]),
              ),
              title: Text(tenant.name),
              subtitle: Text('${tenant.phone} • Room ${tenant.assignedRoom} • Check-in: ${tenant.moveInDate.toString().split(' ')[0]}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Show tenant details
              },
            );
          },
        );
      },
    );
  }
}
