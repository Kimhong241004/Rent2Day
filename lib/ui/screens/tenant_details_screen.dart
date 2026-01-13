import 'package:flutter/material.dart';
import '../../models/tenant.dart';
import '../../data/json_storage_service.dart';
import 'add_tenant_screen.dart';

class TenantDetailsScreen extends StatefulWidget {
  final JsonStorageService storageService;
  final String tenantId;

  const TenantDetailsScreen({
    Key? key,
    required this.storageService,
    required this.tenantId,
  }) : super(key: key);

  @override
  _TenantDetailsScreenState createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends State<TenantDetailsScreen> {
  late Future<Tenant?> _tenantFuture;

  @override
  void initState() {
    super.initState();
    _loadTenant();
  }

  void _loadTenant() {
    debugPrint('===== LOADING TENANT: ${widget.tenantId} =====');
    _tenantFuture = _getTenantById(widget.tenantId);
  }

  Future<Tenant?> _getTenantById(String tenantId) async {
    debugPrint('Fetching tenant with ID: $tenantId');
    final tenants = await widget.storageService.getTenants();
    debugPrint('Total tenants in storage: ${tenants.length}');
    try {
      final tenant = tenants.firstWhere((t) => t.id == tenantId);
      debugPrint('Found tenant: ${tenant.name}');
      return tenant;
    } catch (e) {
      debugPrint('ERROR: Tenant not found - $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tenant?>(
      future: _tenantFuture,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Tenants Detail'),
            backgroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context, false),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () {
                  if (snapshot.hasData && snapshot.data != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTenantScreen(
                          storageService: widget.storageService,
                          tenantToEdit: snapshot.data!,
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        _loadTenant();
                      });
                    }).then((_) {
                      // Return true to indicate tenant was updated
                      Navigator.pop(context, true);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  if (snapshot.hasData && snapshot.data != null) {
                    _showDeleteConfirmation(snapshot.data!);
                  }
                },
              ),
            ],
          ),
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<Tenant?> snapshot) {
    debugPrint('===== BUILDING TENANT DETAILS BODY =====');
    debugPrint('Connection state: ${snapshot.connectionState}');
    debugPrint('Has data: ${snapshot.hasData}');
    debugPrint('Data: ${snapshot.data}');
    
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Tenant not found', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    final tenant = snapshot.data!;
    debugPrint('Displaying tenant: ${tenant.name}');

    // Calculate renting duration
    final now = DateTime.now();
    final rentalMonths = (now.year - tenant.moveInDate.year) * 12 +
        (now.month - tenant.moveInDate.month);

    return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tenant Name
                  Center(
                    child: Text(
                      tenant.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Contact Information Section
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactCard(Icons.phone, 'Phone', tenant.phone),

                  const SizedBox(height: 30),

                  // Rental Information Section
                  const Text(
                    'Rental Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRentalCard('Room Number', tenant.assignedRoom, isSvg: true, svgPath: 'assets/Icons/Rooms.svg'),
                  const SizedBox(height: 12),
                  _buildRentalCard('National ID', tenant.nationalId, icon: Icons.badge),
                  const SizedBox(height: 12),
                  _buildRentalCard('Deposit', '\$${tenant.deposit.toStringAsFixed(2)}', icon: Icons.attach_money),
                  const SizedBox(height: 12),
                  _buildRentalCard('Start Date', tenant.moveInDate.toString().split(' ')[0], icon: Icons.calendar_today),


                  const SizedBox(height: 30),

                  // Renting Duration Chip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF56CCF2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Renting Duration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$rentalMonths months',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
      }

  Widget _buildContactCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(String label, String value, {bool isSvg = false, String? svgPath, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.info, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Tenant tenant) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: Text('Are you sure you want to delete ${tenant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.storageService.deleteTenant(tenant.id);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tenant deleted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
