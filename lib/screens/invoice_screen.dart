import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/invoice.dart';
import '../services/app_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageIndex = 0;
  String? _selectedStatus;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvoices());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  AppService _getAppService() {
    return context.read<AppService>();
  }

  Future<void> _loadInvoices({bool reset = false}) async {
    if (reset) {
      setState(() {
        _pageIndex = 0;
        _invoices = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else if (_isLoading && _invoices.isEmpty) {
      // Continue loading
    } else if (_invoices.isNotEmpty && !reset) {
      return; // Already loaded
    }

    try {
      final user = context.read<AuthController>().currentUser;
      final appService = _getAppService();
      
      List<Invoice> newInvoices;
      
      if (user != null) {
        newInvoices = await appService.fetchInvoices(
          userId: user.id,
          status: _selectedStatus,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          pageIndex: _pageIndex,
        );
      } else {
        newInvoices = await appService.fetchInvoices(
          status: _selectedStatus,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          pageIndex: _pageIndex,
        );
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _invoices = newInvoices;
          } else {
            _invoices.addAll(newInvoices);
          }
          _hasMore = newInvoices.length >= 50;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'حدث خطأ في تحميل البيانات', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _pageIndex++;
    });
    await _loadInvoices();
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadInvoices(reset: true);
  }

  void _search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadInvoices(reset: true);
    });
  }

  Future<void> _refresh() async {
    await _loadInvoices(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفواتير'),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: _filterByStatus,
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('الكل')),
                const PopupMenuItem(value: '1', child: Text('مدفوع')),
                const PopupMenuItem(value: '2', child: Text('غير مدفوع')),
                const PopupMenuItem(value: '3', child: Text('مدفوع جزئياً')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث برقم الفاتورة...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: _search,
              ),
            ),
            if (_invoices.isNotEmpty) _SummaryCards(invoices: _invoices),
            Expanded(
              child: _isLoading && _invoices.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _invoices.isEmpty
                      ? _EmptyState(onRefresh: _refresh)
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _invoices.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _invoices.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final invoice = _invoices[index];
                              return _InvoiceCard(
                                invoice: invoice,
                                onTap: () => _showInvoiceDetails(invoice),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _InvoiceDetailsSheet(invoice: invoice),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.invoices});

  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    final totalAmount = invoices.fold<double>(0, (sum, i) => sum + i.totalAmount);
    final paidAmount = invoices.fold<double>(0, (sum, i) => sum + i.paidAmount);
    final remainingAmount = totalAmount - paidAmount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.receipt_long,
              label: 'الإجمالي',
              value: '${totalAmount.toStringAsFixed(0)} ج.م',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              icon: Icons.check_circle,
              label: 'المدفوع',
              value: '${paidAmount.toStringAsFixed(0)} ج.م',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              icon: Icons.pending,
              label: 'المتبقي',
              value: '${remainingAmount.toStringAsFixed(0)} ج.م',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt,
                      color: _getStatusColor(invoice.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.userName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: invoice.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(
                    icon: Icons.calendar_today,
                    value: _formatDate(invoice.createdDate),
                  ),
                  _InfoItem(
                    icon: Icons.attach_money,
                    value: '${invoice.totalAmount.toStringAsFixed(0)} ج.م',
                    valueColor: Colors.green,
                  ),
                  if (!invoice.isPaid)
                    _InfoItem(
                      icon: Icons.warning,
                      value: '${invoice.remainingAmount.toStringAsFixed(0)} ج.م',
                      valueColor: Colors.red,
                    ),
                ],
              ),
              if (invoice.isOverdue) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'متأخر منذ ${_getDaysOverdue(invoice.dueDate)} يوم',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.unpaid:
        return Colors.red;
      case InvoiceStatus.partial:
        return Colors.orange;
      case InvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  int _getDaysOverdue(DateTime dueDate) {
    return DateTime.now().difference(dueDate).inDays;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case InvoiceStatus.paid:
        color = Colors.green;
        label = 'مدفوع';
        break;
      case InvoiceStatus.unpaid:
        color = Colors.red;
        label = 'غير مدفوع';
        break;
      case InvoiceStatus.partial:
        color = Colors.orange;
        label = 'جزئي';
        break;
      case InvoiceStatus.cancelled:
        color = Colors.grey;
        label = 'ملغي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.text2),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد فواتير',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تحميل'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailsSheet extends StatelessWidget {
  const _InvoiceDetailsSheet({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.receipt,
                  color: _getStatusColor(invoice.status),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: 'معلومات الفاتورة',
            children: [
              _DetailRow('رقم الفاتورة', invoice.invoiceNumber),
              _DetailRow('تاريخ الإنشاء', _formatDate(invoice.createdDate)),
              _DetailRow('تاريخ الاستحقاق', _formatDate(invoice.dueDate)),
              _DetailRow('الحالة', invoice.status.label),
            ],
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'المبالغ',
            children: [
              _DetailRow('المبلغ الإجمالي', '${invoice.totalAmount.toStringAsFixed(2)} ج.م'),
              _DetailRow('المبلغ المدفوع', '${invoice.paidAmount.toStringAsFixed(2)} ج.م', valueColor: Colors.green),
              _DetailRow('المبلغ المتبقي', '${invoice.remainingAmount.toStringAsFixed(2)} ج.م', valueColor: Colors.red),
            ],
          ),
          if (invoice.paymentMethod != null) ...[
            const SizedBox(height: 16),
            _DetailSection(
              title: 'معلومات الدفع',
              children: [
                _DetailRow('طريقة الدفع', invoice.paymentMethod!),
                if (invoice.paidDate != null)
                  _DetailRow('تاريخ الدفع', _formatDate(invoice.paidDate!)),
                if (invoice.transactionId != null)
                  _DetailRow('رقم العملية', invoice.transactionId!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.unpaid:
        return Colors.red;
      case InvoiceStatus.partial:
        return Colors.orange;
      case InvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.text2),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
