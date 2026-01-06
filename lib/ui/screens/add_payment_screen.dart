import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import '../../models/payment.dart';
import '../../models/room.dart';
import '../../data/storage_service.dart';

class AddPaymentScreen extends StatefulWidget {
  final StorageService storageService;
  const AddPaymentScreen({Key? key, required this.storageService})
      : super(key: key);

  @override
  _AddPaymentScreenState createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRoom = '';
  bool _markAsPaid = false;
  bool _isLoading = false;
  List<Room> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() async {
    final rooms = await widget.storageService.getRooms();
    setState(() {
      _availableRooms = rooms;
    });
  }

  void _savePayment() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Find selected room
    final selectedRoom = _availableRooms.firstWhere(
      (r) => r.roomNumber == _selectedRoom,
      orElse: () => _availableRooms.first,
    );

    final payment = Payment(
      id: const Uuid().v4(),
      roomNumber: selectedRoom.roomNumber,
      tenantName: selectedRoom.currentTenant ?? 'No Tenant',
      tenantPhone: '000 000 000',
      amount: 0,
      date: DateTime.now(),
      isPaid: _markAsPaid,
    );

    widget.storageService.addPayment(payment).then((_) {
      Navigator.pop(context, true);
    }).catchError((e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    });
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
          'Add Payment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Select Room Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRoom.isEmpty ? null : _selectedRoom,
                decoration: InputDecoration(
                  labelText: 'Select Rooms',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      'assets/Icons/Rooms.svg',
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
                items: _availableRooms
                    .map((room) => DropdownMenuItem(
                          value: room.roomNumber,
                          child: Text(room.roomNumber),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoom = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Mark as Paid Checkbox
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _markAsPaid = !_markAsPaid;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _markAsPaid ? const Color(0xFF56CCF2) : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _markAsPaid
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 18,
                                color: Color(0xFF56CCF2),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Mark as Paid',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Add Payment Button
              ElevatedButton(
                onPressed: _isLoading ? null : _savePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF56CCF2),
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _isLoading ? 'Adding...' : 'Add Payment record',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
