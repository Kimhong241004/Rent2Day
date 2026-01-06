import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/tenant.dart';
import '../../models/room.dart';
import '../../data/storage_service.dart';

class BookTenantScreen extends StatefulWidget {
  final StorageService storageService;
  const BookTenantScreen({Key? key, required this.storageService})
      : super(key: key);

  @override
  _BookTenantScreenState createState() => _BookTenantScreenState();
}

class _BookTenantScreenState extends State<BookTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  DateTime? _checkInDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _depositCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
      });
    }
  }

  void _saveBooking() async {
    if (!_formKey.currentState!.validate() || _checkInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select check-in date')),
      );
      return;
    }

    // Check if room is already occupied
    final rooms = await widget.storageService.getRooms();
    final tenants = await widget.storageService.getTenants();
    
    final selectedRoom = rooms.firstWhere(
      (room) => room.roomNumber == _roomCtrl.text.trim(),
      orElse: () => null as dynamic,
    ) as Room?;

    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room not found')),
      );
      return;
    }

    // Check if room has an active tenant (tenant without moveOutDate)
    final hasActiveTenant = tenants.any((tenant) =>
        tenant.assignedRoom == _roomCtrl.text.trim() &&
        tenant.moveOutDate == null);

    if (selectedRoom.status == 'Occupied' || hasActiveTenant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This room is already occupied. Please select an available room.')),
      );
      return;
    }

    final tenant = Tenant(
      id: DateTime.now().toString(),
      name: _nameCtrl.text.trim(),
      nationalId: '',
      phone: _phoneCtrl.text.trim(),
      deposit: double.parse(_depositCtrl.text.trim()),
      assignedRoom: _roomCtrl.text.trim(),
      moveInDate: _checkInDate!,
    );

    // Update room status to Occupied
    final updatedRoom = Room(
      id: selectedRoom.id,
      roomNumber: selectedRoom.roomNumber,
      floor: selectedRoom.floor,
      roomType: selectedRoom.roomType,
      rentAmount: selectedRoom.rentAmount,
      deposit: selectedRoom.deposit,
      status: 'Occupied',
      currentTenant: tenant.name,
    );

    widget.storageService.addTenant(tenant).then((_) {
      widget.storageService.updateRoom(updatedRoom).then((_) {
        Navigator.pop(context, true);
      });
    });
  }

  Widget _buildTextField(String label, String icon, TextEditingController controller,
      {String? Function(String?)? validator, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? (value) {
        if (value?.isEmpty ?? true) return '$label is required';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF56CCF2), width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Room Booking',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildTextField(
                  'Full Name',
                  'assets/Icons/Tenants.svg',
                  _nameCtrl,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Phone Number',
                  'assets/Icons/Phone.svg',
                  _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Deposit',
                  'assets/Icons/Deposit.svg',
                  _depositCtrl,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Deposit is required';
                    if (double.tryParse(value!) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Room Number',
                  'assets/Icons/Rooms.svg',
                  _roomCtrl,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _selectDate,
                  child: TextFormField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: _checkInDate == null
                          ? 'Check IN'
                          : 'Check IN: ${_checkInDate!.toLocal().toString().split(' ')[0]}',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SvgPicture.asset(
                          'assets/Icons/Calendar.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF56CCF2), width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF56CCF2),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Add Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
