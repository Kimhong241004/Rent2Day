import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../data/json_storage_service.dart';
import 'add_payment_screen.dart';

class PaymentsScreen extends StatefulWidget {
  final JsonStorageService storageService;

  const PaymentsScreen({Key? key, required this.storageService})
    : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Payment>> _paymentsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = widget.storageService.getPayments();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Payment> _filterPayments(List<Payment> payments, int tabIndex) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    switch (tabIndex) {
      case 0: // All
        return payments;
      case 1: // Unpaid
        return payments.where((p) => !p.isPaid).toList();
      case 2: // Paid
        return payments.where((p) => p.isPaid).toList();
      case 3: // Last 3 Months
        return payments.where((p) => p.date.isAfter(threeMonthsAgo)).toList();
      default:
        return payments;
    }
  }

  int _getUnpaidCount(List<Payment> payments) {
    return payments.where((p) => !p.isPaid).length;
  }

  int _getPaidCount(List<Payment> payments) {
    return payments.where((p) => p.isPaid).length;
  }

  double _getTotalAmount(List<Payment> payments) {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  void _refreshPayments() {
    setState(() {
      _paymentsFuture = widget.storageService.getPayments();
    });
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
        int unpaidCount = _getUnpaidCount(allPayments);
        int paidCount = _getPaidCount(allPayments);
        List<Payment> filteredPayments = _filterPayments(
          allPayments,
          _tabController.index,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'Payments',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF2196F3),
                  size: 28,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPaymentScreen(
                        storageService: widget.storageService,
                      ),
                    ),
                  );
                  _refreshPayments();
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2196F3),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2196F3),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    const Tab(text: 'All'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Unpaid'),
                          if (unpaidCount > 0) ...[
                            const SizedBox(width: 6),
                            _buildBadge(unpaidCount, Colors.red),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Paid'),
                          if (paidCount > 0) ...[
                            const SizedBox(width: 6),
                            _buildBadge(paidCount, Colors.green),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Last 3M'),
                  ],
                  onTap: (index) {
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPaymentList(allPayments, allPayments),
              _buildPaymentList(
                allPayments.where((p) => !p.isPaid).toList(),
                allPayments,
              ),
              _buildPaymentList(
                allPayments.where((p) => p.isPaid).toList(),
                allPayments,
              ),
              _buildPaymentList(
                allPayments.where((p) {
                  final now = DateTime.now();
                  final threeMonthsAgo = DateTime(
                    now.year,
                    now.month - 3,
                    now.day,
                  );
                  return p.date.isAfter(threeMonthsAgo);
                }).toList(),
                allPayments,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentList(List<Payment> payments, List<Payment> allPayments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Sort payments by date (most recent first)
    payments.sort((a, b) => b.date.compareTo(a.date));

    final totalAmount = _getTotalAmount(payments);
    final paidAmount = _getTotalAmount(
      payments.where((p) => p.isPaid).toList(),
    );
    final unpaidAmount = _getTotalAmount(
      payments.where((p) => !p.isPaid).toList(),
    );

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${payments.length} payment${payments.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Paid',
                      '\$${paidAmount.toStringAsFixed(2)}',
                      Colors.green[300]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      'Unpaid',
                      '\$${unpaidAmount.toStringAsFixed(2)}',
                      Colors.red[300]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Payment List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment, allPayments);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment, List<Payment> allPayments) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPaymentDetails(payment, allPayments),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: payment.isPaid ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Payment Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              payment.tenantName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: payment.isPaid
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              payment.isPaid ? 'Paid' : 'Unpaid',
                              style: TextStyle(
                                color: payment.isPaid
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Room ${payment.roomNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(payment.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(Payment payment, List<Payment> allPayments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentDetailsSheet(payment, allPayments),
    );
  }

  Widget _buildPaymentDetailsSheet(Payment payment, List<Payment> allPayments) {
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: payment.isPaid
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.isPaid ? 'Paid' : 'Unpaid',
                    style: TextStyle(
                      color: payment.isPaid ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              Icons.person_outline,
              'Tenant Name',
              payment.tenantName,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.phone_outlined, 'Phone', payment.tenantPhone),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.meeting_room_outlined,
              'Room Number',
              payment.roomNumber,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Payment Date',
              dateFormat.format(payment.date),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.attach_money,
              'Amount',
              '\$${payment.amount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final updatedPayment = Payment(
                        id: payment.id,
                        roomNumber: payment.roomNumber,
                        tenantName: payment.tenantName,
                        tenantPhone: payment.tenantPhone,
                        amount: payment.amount,
                        date: payment.date,
                        isPaid: !payment.isPaid,
                      );
                      await widget.storageService.updatePayment(updatedPayment);
                      _refreshPayments();
                    },
                    icon: Icon(
                      payment.isPaid
                          ? Icons.cancel_outlined
                          : Icons.check_circle_outline,
                    ),
                    label: Text(payment.isPaid ? 'Mark Unpaid' : 'Mark Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: payment.isPaid
                          ? Colors.orange
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Payment'),
                        content: const Text(
                          'Are you sure you want to delete this payment?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await widget.storageService.deletePayment(payment.id);
                      _refreshPayments();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2196F3)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
