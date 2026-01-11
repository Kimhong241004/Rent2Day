import 'package:flutter/material.dart';
import '../../models/room.dart';
import '../../models/tenant.dart';
import '../../data/json_storage_service.dart';
import 'add_tenant_screen.dart';

class RoomTenantDetailsScreen extends StatefulWidget {
  final JsonStorageService storageService;
  final Room room;

  const RoomTenantDetailsScreen({
    Key? key,
    required this.storageService,
    required this.room,
  }) : super(key: key);

  @override
  _RoomTenantDetailsScreenState createState() => _RoomTenantDetailsScreenState();
}

class _RoomTenantDetailsScreenState extends State<RoomTenantDetailsScreen> {
  late Future<Tenant?> _tenantFuture;

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  void _loadTenant() {
    _tenantFuture = _getTenantById(widget.room.currentTenant ?? '');
  }

  Future<Tenant?> _getTenantById(String tenantId) async {
    if (tenantId.isEmpty) return null;
    final tenants = await widget.storageService.getTenants();
    try {
      return tenants.firstWhere((t) => t.id == tenantId);
    } catch (e) {
      return null;
    }
  }

  String _getRentingDuration(Tenant tenant) {
    final now = DateTime.now();
    final moveInDate = tenant.moveInDate;
    final difference = now.difference(moveInDate);
    
    final days = difference.inDays;
    if (days < 1) return '0 days';
    if (days < 30) return '$days days';
    
    final months = (days / 30).floor();
    if (months < 12) return '$months month${months > 1 ? 's' : ''}';
    
    final years = (months / 12).floor();
    return '$years year${years > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tenants Detail',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          FutureBuilder<Tenant?>(
            future: _tenantFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final tenant = snapshot.data!;
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
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
                            setState(() {
                              _loadTenant();
                            });
                            // Notify parent screen to refresh
                            Navigator.pop(context, true);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmation(tenant);
                      },
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: FutureBuilder<Tenant?>(
        future: _tenantFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tenant not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final tenant = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Information Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: tenant.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Rental Information Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rental Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem(
                        icon: Icons.apartment,
                        label: 'Room Number',
                        value: widget.room.roomNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.credit_card,
                        label: 'National ID',
                        value: tenant.nationalId,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.attach_money,
                        label: 'Monthly Rent',
                        value: '\$${widget.room.rentAmount.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        label: 'Start Date',
                        value: tenant.moveInDate.toString().split(' ')[0],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.savings,
                        label: 'Deposit',
                        value: '\$${tenant.deposit.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Renting Duration
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF56CCF2), Color(0xFF2196F3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Renting Duration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRentingDuration(tenant),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(Tenant tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: Text('Are you sure you want to delete ${tenant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Delete tenant
              await widget.storageService.deleteTenant(tenant.id);
              
              // Update room to available
              final updatedRoom = Room(
                id: widget.room.id,
                roomNumber: widget.room.roomNumber,
                floor: widget.room.floor,
                roomType: widget.room.roomType,
                rentAmount: widget.room.rentAmount,
                deposit: widget.room.deposit,
                status: 'Available',
                currentTenant: null,
              );
              await widget.storageService.updateRoom(updatedRoom);
              
              if (mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tenant deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
