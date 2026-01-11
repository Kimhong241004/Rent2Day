import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/payment.dart';
import '../../data/json_storage_service.dart';
import 'add_payment_screen.dart';

class PaymentsScreen extends StatefulWidget {
  final JsonStorageService storageService;
  const PaymentsScreen({Key? key, required this.storageService}) : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Payment>> _paymentsFuture;
  DateTime _currentMonth = DateTime.now();
  late TabController _tabController;
  final List<String> _filterOptions = ['All', 'Paid', 'Unpaid', 'Last3M'];

  @override
  void initState() {
    super.initState();
    _paymentsFuture = widget.storageService.getPayments();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    List<Payment> filtered = payments.where((p) {
      return p.date.year == _currentMonth.year && p.date.month == _currentMonth.month;
    }).toList();

    String selectedFilter = _filterOptions[_tabController.index];
    if (selectedFilter == 'Paid') {
      filtered = filtered.where((p) => p.isPaid).toList();
    } else if (selectedFilter == 'Unpaid') {
      filtered = filtered.where((p) => !p.isPaid).toList();
    }

    return filtered;
  }

  double _getTotalPaid(List<Payment> payments) {
    return payments.where((p) => p.isPaid && p.date.year == _currentMonth.year && p.date.month == _currentMonth.month).fold(0, (sum, p) => sum + p.amount);
  }

  double _getTotalUnpaid(List<Payment> payments) {
    return payments.where((p) => !p.isPaid && p.date.year == _currentMonth.year && p.date.month == _currentMonth.month).fold(0, (sum, p) => sum + p.amount);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: _paymentsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        List<Payment> allPayments = snapshot.data ?? [];
        double totalPaid = _getTotalPaid(allPayments);
        double totalUnpaid = _getTotalUnpaid(allPayments);
        List<Payment> filteredPayments = _filterPayments(allPayments);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: const Text(
                      'Rent Payments',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Month Navigation Card
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF56CCF2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _previousMonth,
                            child: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: GestureDetector(
                              onTap: _showMonthYearPicker,
                              child: Text(
                                '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _nextMonth,
                            child: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Summary Cards
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                        Container(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Paid',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalPaid.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Unpaid',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalUnpaid.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Filter Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF56CCF2),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF56CCF2),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Paid'),
                      Tab(text: 'Unpaid'),
                      Tab(text: 'Last 3M'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Payment List
                  if (filteredPayments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No payments found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ...filteredPayments.map((payment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
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
                                    'Room ${payment.roomNumber}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${payment.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: payment.isPaid ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                payment.tenantName,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              Text(
                                payment.tenantPhone,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              Text(
                                'Due for ${_monthName(payment.date.month)} ${payment.date.year}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final updatedPayment = Payment(
                                        id: payment.id,
                                        roomNumber: payment.roomNumber,
                                        tenantName: payment.tenantName,
                                        tenantPhone: payment.tenantPhone,
                                        amount: payment.amount,
                                        date: payment.date,
                                        isPaid: !payment.isPaid,
                                      );
                                      widget.storageService.updatePayment(updatedPayment).then((_) {
                                        setState(() {
                                          _paymentsFuture = widget.storageService.getPayments();
                                        });
                                      });
                                    },
                                    child: Text(
                                      payment.isPaid ? '✓ Mark Unpaid' : '✓ Mark Paid',
                                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      widget.storageService.deletePayment(payment.id).then((_) {
                                        setState(() {
                                          _paymentsFuture = widget.storageService.getPayments();
                                        });
                                      });
                                    },
                                    child: const Text(
                                      '🗑 Delete',
                                      style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          floatingActionButton: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPaymentScreen(storageService: widget.storageService),
                  ),
                ).then((result) {
                  if (result == true) {
                    setState(() {
                      _paymentsFuture = widget.storageService.getPayments();
                    });
                  }
                });
              },
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

  String _monthName(int month) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  void _showMonthYearPicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (selectedDate != null) {
      setState(() {
        _currentMonth = DateTime(selectedDate.year, selectedDate.month);
      });
    }
  }
}
