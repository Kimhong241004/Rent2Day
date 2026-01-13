import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../models/tenant.dart';
import '../../data/json_storage_service.dart';
import 'add_room_screen.dart';
import 'add_tenant_screen.dart';

class SearchScreen extends StatefulWidget {
  final JsonStorageService storageService;
  const SearchScreen({Key? key, required this.storageService}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Room>> _allRoomsFuture;
  late Future<List<Tenant>> _allTenantsFuture;
  List<Room> _searchResults = [];
  List<Tenant> _searchedTenants = [];
  TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedFilter = 'All'; // All, Available, Occupied, Maintenance
  Set<String> _selectedTenants = {}; // Empty set means all tenants

  @override
  void initState() {
    super.initState();
    _allRoomsFuture = widget.storageService.getRooms();
    _allTenantsFuture = widget.storageService.getTenants();
    _searchController.addListener(_performSearch);
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index == 4) {
          // Tenants tab
          _searchController.clear();
        } else {
          _selectedFilter = ['All', 'Available', 'Occupied', 'Maintenance'][_tabController.index];
        }
      });
      _performSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final allRooms = await _allRoomsFuture;
    final allTenants = await _allTenantsFuture;
    final query = _searchController.text.toLowerCase();
    bool showTenantsMode = _tabController.index == 4;

    debugPrint('===== SEARCH =====');
    debugPrint('Query: "$query"');
    debugPrint('Tab index: ${_tabController.index}');
    debugPrint('Filter: $_selectedFilter');
    debugPrint('Total rooms: ${allRooms.length}');

    setState(() {
      // Common: Search tenants by name (used in both modes)
      if (query.isNotEmpty) {
        _searchedTenants = allTenants
            .where((tenant) => tenant.name.toLowerCase().contains(query))
            .toList();
        debugPrint('Matching tenants: ${_searchedTenants.length}');
      } else {
        _searchedTenants = showTenantsMode ? allTenants : [];
      }

      if (showTenantsMode) {
        // In Tenants mode, display search results
        debugPrint('Tenants mode - showing ${_searchedTenants.length} tenants');
      } else {
        // In Rooms mode, search by room OR tenant
        _searchResults = allRooms.where((room) {
          // Filter by search query (room number, room type)
          final matchesRoomSearch = room.roomNumber.toLowerCase().contains(query) ||
              room.roomType.toLowerCase().contains(query);

          // Check if room's tenant matches searched tenant name
          final matchesTenantSearch = _searchedTenants.any((t) => t.id == room.currentTenant);

          // Filter by status tab
          final matchesFilter =
              _selectedFilter.isEmpty || _selectedFilter == 'All' || room.status == _selectedFilter;

          // Match if: (room search OR tenant search OR no search) AND status filter
          final matchesSearch = query.isEmpty || matchesRoomSearch || matchesTenantSearch;
          
          return matchesSearch && matchesFilter;
        }).toList();
        debugPrint('Search results: ${_searchResults.length} rooms');
        if (_searchResults.isNotEmpty) {
          debugPrint('First result: ${_searchResults.first.roomNumber}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Room>>(
        future: _allRoomsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _tabController.index == 4
                          ? 'Search by tenant name...'
                          : 'Search by room number, type, or tenant...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setState(() {});
                      _performSearch();
                    },
                  ),
                  const SizedBox(height: 20),
                  // TabBar for filters
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF56CCF2),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF56CCF2),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Available'),
                      Tab(text: 'Occupied'),
                      Tab(text: 'Maintenance'),
                      Tab(text: 'Tenants'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Content based on selected tab
                  _buildTabContent(snapshot),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(AsyncSnapshot<List<Room>> snapshot) {
    bool showTenantsMode = _tabController.index == 4;
    
    if (showTenantsMode) {
      // Tenants Mode Results
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchedTenants.isNotEmpty) ...[
            Text(
              'Results: ${_searchedTenants.length} tenant${_searchedTenants.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ..._searchedTenants.map((tenant) {
              // Find all rooms where this tenant is assigned (using tenant ID)
              final allRooms = snapshot.data ?? [];
              final tenantRooms = allRooms
                  .where((room) => room.currentTenant == tenant.id)
                  .toList();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tenant.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Phone: ${tenant.phone}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'ID: ${tenant.nationalId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Deposit: \$${tenant.deposit.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (tenantRooms.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Living in:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...tenantRooms.map((room) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• Room ${room.roomNumber} (${room.roomType})',
                          style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                        ),
                      )).toList(),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Not assigned to any room',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    // Action Buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddTenantScreen(
                                    storageService: widget.storageService,
                                    tenantToEdit: tenant,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _performSearch();
                                }
                              });
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showDeleteConfirmation('${tenant.name}', () async {
                                await widget.storageService.deleteTenant(tenant.id);
                                setState(() {
                                  _allRoomsFuture = widget.storageService.getRooms();
                                  _allTenantsFuture = widget.storageService.getTenants();
                                });
                                _performSearch();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tenant deleted successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              });
                            },
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ] else
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.person_off,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tenants found',
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching by tenant name',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      // Rooms Mode Results
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results Count
          if (_searchResults.isNotEmpty)
            Text(
              'Results: ${_searchResults.length} room${_searchResults.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          if (_searchResults.isNotEmpty)
            const SizedBox(height: 12),

          // Search Results
          if (_searchResults.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.search_off,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching by room number, type, or tenant name',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            FutureBuilder<List<Tenant>>(
              future: _allTenantsFuture,
              builder: (context, tenantSnapshot) {
                final allTenants = tenantSnapshot.data ?? [];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final room = _searchResults[index];
                    return _buildRoomCard(room, allTenants);
                  },
                );
              },
            ),
        ],
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Occupied':
        return Colors.orange;
      case 'Maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(String itemName, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room, List<Tenant> allTenants) {
    final isOccupied = room.status == 'Occupied';
    
    // Find tenant name by ID
    String tenantName = 'N/A';
    if (room.currentTenant != null) {
      try {
        final tenant = allTenants.firstWhere((t) => t.id == room.currentTenant);
        tenantName = tenant.name;
      } catch (e) {
        tenantName = 'Unknown Tenant';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isOccupied ? Border.all(color: Colors.orange, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.roomType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(room.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  room.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rent Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${room.rentAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (room.currentTenant != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tenant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tenantName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          // Action Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddRoomScreen(
                          storageService: widget.storageService,
                          roomToEdit: room,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        setState(() {
                          _allRoomsFuture = widget.storageService.getRooms();
                          _allTenantsFuture = widget.storageService.getTenants();
                        });
                        _performSearch();
                      }
                    });
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation('Room ${room.roomNumber}', () async {
                      await widget.storageService.deleteRoom(room.id);
                      setState(() {
                        _allRoomsFuture = widget.storageService.getRooms();
                        _allTenantsFuture = widget.storageService.getTenants();
                      });
                      _performSearch();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Room deleted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
