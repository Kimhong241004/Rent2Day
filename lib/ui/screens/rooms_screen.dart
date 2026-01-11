import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/room.dart';
import '../../models/tenant.dart';
import '../../data/json_storage_service.dart';
import '../widgets/index.dart';
import 'add_room_screen.dart';
import 'tenant_details_screen.dart';

class RoomsScreen extends StatefulWidget {
  final JsonStorageService storageService;
  const RoomsScreen({Key? key, required this.storageService}) : super(key: key);

  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<Map<String, dynamic>> _roomsAndTenantsFuture;
  String _selectedFloor = 'All'; // Filter by floor

  @override
  void initState() {
    super.initState();
    _loadRoomsAndTenants();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRoomsAndTenants(); // Refresh rooms every time screen is shown
  }

  void _loadRoomsAndTenants() {
    _roomsAndTenantsFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final rooms = await widget.storageService.getRooms();
    final tenants = await widget.storageService.getTenants();
    return {'rooms': rooms, 'tenants': tenants};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _roomsAndTenantsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Room> rooms = snapshot.data?['rooms'] ?? [];
        List<Tenant> tenants = snapshot.data?['tenants'] ?? [];

        // Create a map for quick tenant lookup
        final tenantMap = {for (var tenant in tenants) tenant.id: tenant};

        // Group rooms by floor
        Map<String, List<Room>> roomsByFloor = {};
        for (var room in rooms) {
          final floor = room.floor;
          roomsByFloor.putIfAbsent(floor, () => []);
          roomsByFloor[floor]!.add(room);
        }

        // Sort floors
        final sortedFloors = roomsByFloor.keys.toList()..sort();
        final floorOptions = ['All', ...sortedFloors];

        // Filter rooms based on selected floor
        Map<String, List<Room>> filteredRoomsByFloor = {};
        if (_selectedFloor == 'All') {
          filteredRoomsByFloor = roomsByFloor;
        } else {
          filteredRoomsByFloor[_selectedFloor] = roomsByFloor[_selectedFloor] ?? [];
        }
        final displayFloors = _selectedFloor == 'All' ? sortedFloors : [_selectedFloor];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Rooms Dashboard', style: TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.w600)),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Floor Filter - Simple Tap Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...floorOptions.map((floor) {
                          bool isSelected = _selectedFloor == floor;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFloor = floor;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF56CCF2) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF56CCF2) : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  floor,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                if (rooms.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.home_work_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No rooms added yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first room',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                else
                  ...displayFloors.map((floor) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            floor,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        ...filteredRoomsByFloor[floor]!.map((room) {
                          Color statusColor;
                          String statusText;

                          switch (room.status) {
                            case 'Available':
                              statusColor = Colors.green;
                              statusText = 'Available';
                              break;
                            case 'Occupied':
                              statusColor = Colors.orange;
                              statusText = 'Occupied';
                              break;
                            case 'Maintenance':
                              statusColor = Colors.red;
                              statusText = 'Maintenance';
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusText = room.status;
                          }

                          return GestureDetector(
                            onTap: () => _showRoomDetails(room, tenantMap),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.apartment_outlined, size: 24),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Room ${room.roomNumber}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '\$${room.rentAmount.toStringAsFixed(2)}/month',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF56CCF2),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (room.currentTenant != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              tenantMap[room.currentTenant]?.name ?? 'Unknown Tenant',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          floatingActionButton: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showAddRoomDialog(),
              child: SvgPicture.asset(
                'assets/Icons/add.svg',
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(Color(0xFF56CCF2), BlendMode.srcIn),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddRoomDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoomScreen(storageService: widget.storageService),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          _loadRoomsAndTenants();
        });
      }
    });
  }

  void _showRoomDetails(Room room, Map<String, Tenant> tenantMap) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room ${room.roomNumber}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Floor:', room.roomType),
            _buildDetailRow('Rent Amount:', '\$${room.rentAmount.toStringAsFixed(2)}/month'),
            _buildDetailRow('Status:', room.status),
            if (room.currentTenant != null)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _openTenantScreen(room);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Tenant:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                      Row(
                        children: [
                          Text(
                            tenantMap[room.currentTenant]?.name ?? 'Unknown Tenant',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56CCF2)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF56CCF2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRoomScreen(
                            storageService: widget.storageService,
                            roomToEdit: room,
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _loadRoomsAndTenants();
                        });
                      });
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(room);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openTenantScreen(Room room) async {
    // Get the tenant using the tenant ID
    if (room.currentTenant == null || room.currentTenant!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tenant assigned to this room')),
      );
      return;
    }
    
    final tenants = await widget.storageService.getTenants();
    try {
      final tenant = tenants.firstWhere(
        (t) => t.id == room.currentTenant,
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TenantDetailsScreen(
            storageService: widget.storageService,
            tenantId: tenant.id,
          ),
        ),
      ).then((_) {
        setState(() {
          _loadRoomsAndTenants();
        });
      });
    } catch (e) {
      // Tenant not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tenant not found: ${room.currentTenant}')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return buildDetailRow(label, value);
  }

  void _showDeleteConfirmation(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete Room ${room.roomNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              widget.storageService.deleteRoom(room.id).then((_) {
                setState(() {
                  _loadRoomsAndTenants();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room deleted successfully!')),
                );
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
