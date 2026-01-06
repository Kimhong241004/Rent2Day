import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/room.dart';
import '../../data/storage_service.dart';
import 'add_room_screen.dart';
import 'room_tenant_details_screen.dart';

class RoomsScreen extends StatefulWidget {
  final StorageService storageService;
  const RoomsScreen({Key? key, required this.storageService}) : super(key: key);

  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late Future<List<Room>> _roomsFuture;
  String _selectedFloor = 'All'; // Filter by floor

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRooms(); // Refresh rooms every time screen is shown
  }

  void _loadRooms() {
    _roomsFuture = widget.storageService.getRooms();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Room>>(
      future: _roomsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Room> rooms = snapshot.data ?? [];

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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Rooms Dashboard',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Floor Filter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Floor',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...floorOptions.map((floor) {
                              bool isSelected = _selectedFloor == floor;
                              return Padding(
                                padding: const EdgeInsets.only(right: 24.0),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFloor = floor;
                                    });
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        floor,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected ? const Color(0xFF56CCF2) : Colors.grey[600]!,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: isSelected ? 3 : 0,
                                        width: 45,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF56CCF2),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(1.5),
                                            topRight: Radius.circular(1.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
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
                            onTap: () => _showRoomDetails(room),
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
                                              room.currentTenant ?? '',
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
          _roomsFuture = widget.storageService.getRooms();
        });
      }
    });
  }

  void _showRoomDetails(Room room) {
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
                          Text(room.currentTenant!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF56CCF2))),
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
                          _roomsFuture = widget.storageService.getRooms();
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

  void _openTenantScreen(Room room) {
    // Navigate to room and tenant details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomTenantDetailsScreen(
          storageService: widget.storageService,
          room: room,
        ),
      ),
    ).then((_) {
      setState(() {
        _roomsFuture = widget.storageService.getRooms();
      });
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
                  _roomsFuture = widget.storageService.getRooms();
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
