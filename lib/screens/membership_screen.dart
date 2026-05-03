import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/membership.dart';
import '../services/app_service.dart';
import '../theme/app_colors.dart';
import '../widgets/page_transition_wrapper.dart';
import '../widgets/toast.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final _scrollController = ScrollController();
  
  List<Membership> _memberships = [];
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageIndex = 0;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  Future<void> _loadData({bool reset = false}) async {
    if (reset) {
      setState(() {
        _pageIndex = 0;
        _memberships = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else if (_isLoading && _memberships.isEmpty) {
      // Continue loading
    } else if (_memberships.isNotEmpty && !reset) {
      return; // Already loaded
    }

    try {
      final user = context.read<AuthController>().currentUser;
      final appService = _getAppService();
      
      List<Membership> membershipsData;
      
      if (user != null) {
        membershipsData = await appService.fetchMemberships(
          userId: user.id,
          status: _selectedStatus,
          pageIndex: _pageIndex,
        );
      } else {
        membershipsData = await appService.fetchMemberships(
          status: _selectedStatus,
          pageIndex: _pageIndex,
        );
      }

      final plansData = _plans.isEmpty 
          ? await appService.fetchSubscriptionPlans() 
          : _plans;

      if (mounted) {
        setState(() {
          if (reset) {
            _memberships = membershipsData;
          } else {
            _memberships.addAll(membershipsData);
          }
          _plans = plansData;
          _hasMore = membershipsData.length >= 50;
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
    await _loadData();
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadData(reset: true);
  }

  Future<void> _refresh() async {
    await _loadData(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العضويات'),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: _filterByStatus,
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('الكل')),
                const PopupMenuItem(value: '1', child: Text('نشط')),
                const PopupMenuItem(value: '2', child: Text('منتهي')),
                const PopupMenuItem(value: '3', child: Text('معلق')),
              ],
            ),
          ],
        ),
        body: _isLoading && _memberships.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_plans.isNotEmpty) ...[
                      _PlansSection(plans: _plans),
                      const SizedBox(height: 24),
                    ],
                    _MembershipsSection(
                      memberships: _memberships,
                      isLoadingMore: _isLoadingMore,
                      onViewDetails: _viewMembershipDetails,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _viewMembershipDetails(Membership membership) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MembershipDetailsSheet(membership: membership),
    );
  }
}

class _PlansSection extends StatelessWidget {
  const _PlansSection({required this.plans});

  final List<SubscriptionPlan> plans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الباقات المتاحة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _PlanCard(plan: plan);
            },
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${plan.price.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.durationDays} يوم',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipsSection extends StatelessWidget {
  const _MembershipsSection({
    required this.memberships,
    required this.isLoadingMore,
    required this.onViewDetails,
  });

  final List<Membership> memberships;
  final bool isLoadingMore;
  final void Function(Membership) onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اشتراكاتي',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (memberships.isEmpty)
          _EmptyMemberships()
        else
          ...memberships.map((membership) => _MembershipCard(
                membership: membership,
                onTap: () => onViewDetails(membership),
              )),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.membership,
    required this.onTap,
  });

  final Membership membership;
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
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getStatusColor(membership.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(membership.status),
                      color: _getStatusColor(membership.status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.planName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          membership.userName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: membership.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'تاريخ البدء',
                      value: _formatDate(membership.startDate),
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.event_outlined,
                      label: 'تاريخ الانتهاء',
                      value: _formatDate(membership.endDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.timer_outlined,
                      label: 'الأيام المتبقية',
                      value: '${membership.remainingDays} يوم',
                      valueColor: membership.remainingDays < 7 ? Colors.red : null,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.attach_money,
                      label: 'السعر',
                      value: '${membership.price.toStringAsFixed(0)} ج.م',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.active:
        return Colors.green;
      case MembershipStatus.expired:
        return Colors.red;
      case MembershipStatus.pending:
        return Colors.orange;
      case MembershipStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.active:
        return Icons.check_circle;
      case MembershipStatus.expired:
        return Icons.cancel;
      case MembershipStatus.pending:
        return Icons.pending;
      case MembershipStatus.cancelled:
        return Icons.block;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case MembershipStatus.active:
        color = Colors.green;
        label = 'نشط';
        break;
      case MembershipStatus.expired:
        color = Colors.red;
        label = 'منتهي';
        break;
      case MembershipStatus.pending:
        color = Colors.orange;
        label = 'معلق';
        break;
      case MembershipStatus.cancelled:
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
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.text2),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.text2,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyMemberships extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد اشتراكات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لم تقم بشراء أي اشتراك بعد',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipDetailsSheet extends StatelessWidget {
  const _MembershipDetailsSheet({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Text(
            'تفاصيل الاشتراك',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow(label: 'الخطة', value: membership.planName),
          _DetailRow(label: 'الحالة', value: membership.status.label),
          _DetailRow(label: 'تاريخ البدء', value: _formatDate(membership.startDate)),
          _DetailRow(label: 'تاريخ الانتهاء', value: _formatDate(membership.endDate)),
          _DetailRow(label: 'الأيام المتبقية', value: '${membership.remainingDays} يوم'),
          _DetailRow(label: 'السعر', value: '${membership.price.toStringAsFixed(2)} ج.م'),
          if (membership.paymentMethod != null)
            _DetailRow(label: 'طريقة الدفع', value: membership.paymentMethod!),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text2,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
