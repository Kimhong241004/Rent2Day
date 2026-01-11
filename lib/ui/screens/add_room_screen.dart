import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import '../../models/room.dart';
import '../../data/json_storage_service.dart';

class AddRoomScreen extends StatefulWidget {
  final JsonStorageService storageService;
  final Room? roomToEdit; // null for add mode, Room object for edit mode
  const AddRoomScreen({
    Key? key,
    required this.storageService,
    this.roomToEdit,
  }) : super(key: key);

  @override
  _AddRoomScreenState createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNumberCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _rentCtrl;
  late TextEditingController _depositCtrl;
  late TextEditingController _sizeCtrl;
  String _selectedStatus = 'Available';
  bool _isLoading = false;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.roomToEdit != null;
    _roomNumberCtrl = TextEditingController();
    _floorCtrl = TextEditingController();
    _rentCtrl = TextEditingController();
    _depositCtrl = TextEditingController();
    _sizeCtrl = TextEditingController();

    // If editing, populate fields with existing data
    if (_isEditMode && widget.roomToEdit != null) {
      final room = widget.roomToEdit!;
      _roomNumberCtrl.text = room.roomNumber;
      _floorCtrl.text = room.floor;
      _rentCtrl.text = room.rentAmount.toString();
      _sizeCtrl.text = room.roomType;
      _selectedStatus = room.status;
    }
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _floorCtrl.dispose();
    _rentCtrl.dispose();
    _depositCtrl.dispose();
    _sizeCtrl.dispose();
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
          _isEditMode ? 'Edit Room' : 'Add Room',
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
              // Room Number Field
              _buildSvgTextField(
                controller: _roomNumberCtrl,
                label: 'Room Number',
                hint: 'Enter room number',
                iconPath: 'assets/Icons/Rooms.svg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Room number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Floor Number Field
              _buildSvgTextField(
                controller: _floorCtrl,
                label: 'Floor Number',
                hint: 'Enter floor number',
                iconPath: 'assets/Icons/Floor.svg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Floor number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Monthly Rent Field
              _buildSvgTextField(
                controller: _rentCtrl,
                label: 'Monthly Rent',
                hint: 'Enter monthly rent',
                iconPath: 'assets/Icons/Rent.svg',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Monthly rent is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Deposit Field
              _buildSvgTextField(
                controller: _depositCtrl,
                label: 'Deposit Amount',
                hint: 'Enter deposit required',
                iconPath: 'assets/Icons/Deposit.svg',
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
              // Size Field
              _buildSvgTextField(
                controller: _sizeCtrl,
                label: 'Size (Suitable)',
                hint: 'e.g., 1BHK, 2BHK, Studio',
                iconPath: 'assets/Icons/1p.svg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Size is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Status Dropdown
              _buildStatusDropdown(),
              const SizedBox(height: 40),
              // Add/Edit Rooms Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRoom,
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
                          'Add Rooms',
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

  Widget _buildSvgTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String iconPath,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
          borderSide: const BorderSide(color: Color(0xFF56CCF2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        icon: const Icon(Icons.expand_more, color: Colors.grey),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.check_circle_outline, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        items: const [
          DropdownMenuItem(value: 'Available', child: Text('Available')),
          DropdownMenuItem(value: 'Occupied', child: Text('Occupied')),
          DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedStatus = value);
          }
        },
      ),
    );
  }

  void _saveRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode && widget.roomToEdit != null) {
        // Update existing room
        final updatedRoom = Room(
          id: widget.roomToEdit!.id,
          roomNumber: _roomNumberCtrl.text.trim(),
          floor: _floorCtrl.text.trim(),
          roomType: _sizeCtrl.text.trim(),
          rentAmount: double.parse(_rentCtrl.text.trim()),
          deposit: double.parse(_depositCtrl.text.trim()),
          status: _selectedStatus,
          currentTenant: widget.roomToEdit!.currentTenant,
        );

        await widget.storageService.updateRoom(updatedRoom);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add new room
        final newRoom = Room(
          id: const Uuid().v4(),
          roomNumber: _roomNumberCtrl.text.trim(),
          floor: _floorCtrl.text.trim(),
          roomType: _sizeCtrl.text.trim(),
          rentAmount: double.parse(_rentCtrl.text.trim()),
          deposit: double.parse(_depositCtrl.text.trim()),
          status: _selectedStatus,
          currentTenant: null,
        );

        await widget.storageService.addRoom(newRoom);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room added successfully!'),
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
            content: Text('Error saving room: $e'),
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
