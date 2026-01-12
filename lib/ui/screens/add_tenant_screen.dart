import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/tenant.dart';
import '../../models/room.dart';
import '../../models/payment.dart';
import '../../data/json_storage_service.dart';
import '../widgets/index.dart';

class AddTenantScreen extends StatefulWidget {
  final JsonStorageService storageService;
  final Tenant? tenantToEdit;
  const AddTenantScreen({
    Key? key,
    required this.storageService,
    this.tenantToEdit,
  }) : super(key: key);

  @override
  _AddTenantScreenState createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _nationalIdCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _depositCtrl;
  String _selectedRoom = '';
  late bool _isEditMode;
  bool _isLoading = false;
  List<Room> _availableRooms = [];
  DateTime _selectedMoveInDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.tenantToEdit != null;
    _nameCtrl = TextEditingController();
    _nationalIdCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _depositCtrl = TextEditingController();

    // Set tenant data first if editing
    if (_isEditMode && widget.tenantToEdit != null) {
      final tenant = widget.tenantToEdit!;
      _nameCtrl.text = tenant.name;
      _nationalIdCtrl.text = tenant.nationalId;
      _phoneCtrl.text = tenant.phone;
      _depositCtrl.text = tenant.deposit.toString();
      _selectedRoom = tenant.assignedRoom;
      _selectedMoveInDate = tenant.moveInDate;
    }

    // Then load rooms
    _loadRooms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRooms(); // Refresh rooms every time screen is shown
  }

  Future<void> _loadRooms() async {
    final rooms = await widget.storageService.getRooms();
    final tenants = await widget.storageService.getTenants();
    
    // Filter out rooms that already have active tenants
    // But include the current room if we're editing
    final availableRooms = rooms.where((room) {
      // If editing, always include the current room
      if (_isEditMode && _selectedRoom == room.roomNumber) {
        return true;
      }
      
      // Check if this room has an active tenant (tenant without moveOutDate)
      final hasActiveTenant = tenants.any((tenant) =>
          tenant.assignedRoom == room.roomNumber &&
          tenant.moveOutDate == null);
      return !hasActiveTenant;
    }).toList();
    
    setState(() {
      _availableRooms = availableRooms.cast<Room>();
      // If we're editing and the current room is no longer available, keep it selected
      if (_selectedRoom.isEmpty && availableRooms.isNotEmpty) {
        _selectedRoom = availableRooms.first.roomNumber;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _phoneCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Tenant' : 'Add Tenants',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Full Name Field
              _buildTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Enter tenant name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // National ID Field
              _buildTextField(
                controller: _nationalIdCtrl,
                label: 'National ID',
                hint: 'Enter national ID',
                icon: Icons.badge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'National ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone Number Field
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: 'Enter phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Deposit Field
              _buildTextField(
                controller: _depositCtrl,
                label: 'Deposit',
                hint: 'Enter deposit amount',
                icon: Icons.account_balance_wallet,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deposit is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Move-In Date Field
              _buildDateField(
                label: 'Move-In Date',
                selectedDate: _selectedMoveInDate,
                onDateSelected: (newDate) {
                  setState(() => _selectedMoveInDate = newDate);
                },
              ),
              const SizedBox(height: 16),
              // Assign Rooms Dropdown
              _buildRoomDropdown(),
              const SizedBox(height: 40),
              // Add Tenant Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTenant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF56CCF2),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                         ),
                        )
                      : const Text(
                          'Add Tenants',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return buildTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Icon(Icons.calendar_today, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRoom.isEmpty ? null : _selectedRoom,
        icon: const Icon(Icons.expand_more, color: Colors.grey),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(Icons.meeting_room, color: Colors.grey[600]),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        hint: const Text('Assign Rooms'),
        items: _availableRooms.map((room) {
          return DropdownMenuItem<String>(
            value: room.roomNumber,
            child: Text('Room ${room.roomNumber}'),
          );
        }).toList(),
        onChanged: _isEditMode ? null : (value) {
          if (value != null) {
            setState(() {
              _selectedRoom = value;
              // Auto-load deposit from selected room
              final selectedRoom = _availableRooms.firstWhere(
                (room) => room.roomNumber == value,
                orElse: () => Room(
                  id: '',
                  roomNumber: '',
                  floor: '',
                  roomType: '',
                  rentAmount: 0,
                  deposit: 0,
                  status: 'Available',
                ),
              );
              _depositCtrl.text = selectedRoom.deposit.toString();
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Room assignment is required';
          }
          return null;
        },
      ),
    );
  }

  void _saveTenant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode && widget.tenantToEdit != null) {
        final updatedTenant = Tenant(
          id: widget.tenantToEdit!.id,
          name: _nameCtrl.text.trim(),
          nationalId: _nationalIdCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          deposit: double.parse(_depositCtrl.text.trim()),
          assignedRoom: _selectedRoom,
          moveInDate: _selectedMoveInDate,
          moveOutDate: widget.tenantToEdit!.moveOutDate,
        );

        await widget.storageService.updateTenant(updatedTenant);

        // Update room status when room is changed
        if (widget.tenantToEdit!.assignedRoom != _selectedRoom) {
          final rooms = await widget.storageService.getRooms();
          
          // Update old room to Available if no other tenants
          if (widget.tenantToEdit!.moveOutDate == null) {
            final oldRoom = rooms.firstWhere(
              (room) => room.roomNumber == widget.tenantToEdit!.assignedRoom,
              orElse: () => null as dynamic,
            ) as Room?;
            
            if (oldRoom != null) {
              final updatedOldRoom = Room(
                id: oldRoom.id,
                roomNumber: oldRoom.roomNumber,
                floor: oldRoom.floor,
                roomType: oldRoom.roomType,
                rentAmount: oldRoom.rentAmount,
                deposit: oldRoom.deposit,
                status: 'Available',
                currentTenant: null,
              );
              await widget.storageService.updateRoom(updatedOldRoom);
            }
          }
          
          // Update new room to Occupied
          final newRoom = rooms.firstWhere(
            (room) => room.roomNumber == _selectedRoom,
            orElse: () => null as dynamic,
          ) as Room?;
          
          if (newRoom != null) {
            final updatedNewRoom = Room(
              id: newRoom.id,
              roomNumber: newRoom.roomNumber,
              floor: newRoom.floor,
              roomType: newRoom.roomType,
              rentAmount: newRoom.rentAmount,
              deposit: newRoom.deposit,
              status: 'Occupied',
              currentTenant: updatedTenant.id,
            );
            await widget.storageService.updateRoom(updatedNewRoom);
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tenant updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final newTenant = Tenant(
          id: const Uuid().v4(),
          name: _nameCtrl.text.trim(),
          nationalId: _nationalIdCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          deposit: double.parse(_depositCtrl.text.trim()),
          assignedRoom: _selectedRoom,
          moveInDate: _selectedMoveInDate,
        );

        await widget.storageService.addTenant(newTenant);

        // Update room status to Occupied
        final rooms = await widget.storageService.getRooms();
        final roomToUpdate = rooms.firstWhere(
          (room) => room.roomNumber == _selectedRoom,
          orElse: () => null as dynamic,
        ) as Room?;

        if (roomToUpdate != null) {
          final updatedRoom = Room(
            id: roomToUpdate.id,
            roomNumber: roomToUpdate.roomNumber,
            floor: roomToUpdate.floor,
            roomType: roomToUpdate.roomType,
            rentAmount: roomToUpdate.rentAmount,
            deposit: roomToUpdate.deposit,
            status: 'Occupied',
            currentTenant: newTenant.id,
          );
          await widget.storageService.updateRoom(updatedRoom);

          // Auto-create first month's payment (marked as paid)
          final firstPayment = Payment(
            id: const Uuid().v4(),
            roomNumber: _selectedRoom,
            tenantName: newTenant.name,
            tenantPhone: newTenant.phone,
            amount: roomToUpdate.rentAmount,
            date: _selectedMoveInDate,
            isPaid: true,
          );
          await widget.storageService.addPayment(firstPayment);
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tenant added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tenant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
