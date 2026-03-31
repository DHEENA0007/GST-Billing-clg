import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/auth_provider.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  String? _error;

  List<Invoice> _allInvoices = [];
  List<Customer> _allCustomers = [];
  List<Product> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.get(AppConstants.invoices),
        _api.get(AppConstants.customers),
        _api.get(AppConstants.products),
      ]);

      List invoiceItems = [];
      final ir = results[0];
      if (ir is Map && ir['results'] != null) {
        invoiceItems = ir['results'];
      } else if (ir is List) {
        invoiceItems = ir;
      }

      List customerItems = [];
      final cr = results[1];
      if (cr is Map && cr['results'] != null) {
        customerItems = cr['results'];
      } else if (cr is List) {
        customerItems = cr;
      }

      List productItems = [];
      final pr = results[2];
      if (pr is Map && pr['results'] != null) {
        productItems = pr['results'];
      } else if (pr is List) {
        productItems = pr;
      }

      setState(() {
        _allInvoices =
            invoiceItems.map((i) => Invoice.fromJson(i)).toList();
        _allCustomers =
            customerItems.map((c) => Customer.fromJson(c)).toList();
        _allProducts =
            productItems.map((p) => Product.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double _revenueCollected() {
    return _allInvoices
        .where((inv) =>
            inv.status?.toUpperCase() == 'PAID' ||
            inv.status?.toUpperCase() == 'PARTIAL')
        .fold(0.0, (sum, inv) => sum + (inv.amountPaid ?? 0.0));
  }

  double _pendingReceivables() {
    return _allInvoices
        .where((inv) =>
            inv.status?.toUpperCase() == 'ISSUED' ||
            inv.status?.toUpperCase() == 'PARTIAL')
        .fold(0.0, (sum, inv) {
      final total = inv.total ?? 0.0;
      final amountPaid = inv.amountPaid ?? 0.0;
      return sum + (total - amountPaid);
    });
  }

  int _activeCustomers() {
    final customerIds = _allInvoices
        .where((inv) => inv.customerId != null)
        .map((inv) => inv.customerId!)
        .toSet();
    return customerIds.isNotEmpty
        ? customerIds.length
        : _allCustomers.length;
  }

  double _taxLiability() {
    return _allInvoices
        .where((inv) => inv.status?.toUpperCase() != 'CANCELLED')
        .fold(0.0, (sum, inv) {
      final cgst = inv.cgstTotal ?? 0.0;
      final sgst = inv.sgstTotal ?? 0.0;
      final igst = inv.igstTotal ?? 0.0;
      return sum + cgst + sgst + igst;
    });
  }

  List<Invoice> get _recentInvoices {
    final sorted = List<Invoice>.from(_allInvoices);
    sorted.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
    return sorted.take(5).toList();
  }

  List<Product> get _lowStockProducts =>
      _allProducts.where((p) => p.isLowStock).toList();

  Map<String, double> _monthlyRevenue() {
    final now = DateTime.now();
    final result = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM yy').format(month);
      result[key] = 0;
    }
    for (final inv in _allInvoices) {
      if (inv.status?.toUpperCase() == 'CANCELLED') continue;
      if (inv.date == null) continue;
      try {
        final d = DateTime.parse(inv.date!);
        if (d.isAfter(
            DateTime(now.year, now.month - 5, 1).subtract(const Duration(days: 1)))) {
          final key = DateFormat('MMM yy').format(d);
          if (result.containsKey(key)) {
            result[key] = (result[key] ?? 0) + (inv.total ?? 0);
          }
        }
      } catch (_) {}
    }
    return result;
  }

  String _fmt(double amount) {
    return '₹${NumberFormat('#,##,###.##', 'en_IN').format(amount)}';
  }

  String _fmtK(double val) {
    if (val >= 10000000) return '${(val / 10000000).toStringAsFixed(1)}Cr';
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 900;

    return AppScaffold(
      title: 'Dashboard',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 28,
                    ),
                    child: isWide
                        ? _buildWideLayout(context, auth, theme)
                        : _buildNarrowLayout(context, auth, theme),
                  ),
                ),
    );
  }

  Widget _buildWideLayout(BuildContext context, dynamic auth, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeHeader(auth, theme),
        const SizedBox(height: 32),
        _buildStatsRow(theme),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRevenueChart(theme),
                  const SizedBox(height: 28),
                  _buildRecentInvoices(context, theme),
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionsVertical(context),
                  if (_lowStockProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildLowStockAlert(theme),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, dynamic auth, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeHeader(auth, theme),
        const SizedBox(height: 28),
        _buildStatsGrid(theme),
        const SizedBox(height: 28),
        _buildSectionHeader(context, 'Quick Actions'),
        const SizedBox(height: 16),
        _buildQuickActions(context),
        const SizedBox(height: 28),
        _buildRevenueChart(theme),
        const SizedBox(height: 28),
        _buildRecentInvoices(context, theme),
        if (_lowStockProducts.isNotEmpty) ...[
          const SizedBox(height: 28),
          _buildLowStockAlert(theme),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[600])),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(AuthProvider auth, ThemeData theme) {
    final invoiceCount = _allInvoices.length;
    final paidCount = _allInvoices.where((i) => i.status?.toUpperCase() == 'PAID').length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              (auth.user?.username ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${auth.user?.firstName?.isNotEmpty == true ? auth.user!.firstName! : auth.user?.username ?? 'User'}!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '$invoiceCount Invoices',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '$paidCount Paid',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
    );
  }

  List<Map<String, dynamic>> _statsData() => [
    {
      'title': 'Revenue Collected',
      'value': _fmt(_revenueCollected()),
      'icon': Icons.account_balance_wallet_rounded,
      'colors': [const Color(0xFF6366F1), const Color(0xFF818CF8)],
      'sub': '${_allInvoices.where((i) => i.status?.toUpperCase() == 'PAID').length} paid invoices',
    },
    {
      'title': 'Pending Receivables',
      'value': _fmt(_pendingReceivables()),
      'icon': Icons.hourglass_top_rounded,
      'colors': [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
      'sub': '${_allInvoices.where((i) => i.status?.toUpperCase() == 'ISSUED' || i.status?.toUpperCase() == 'PARTIAL').length} open invoices',
    },
    {
      'title': 'Active Customers',
      'value': _activeCustomers().toString(),
      'icon': Icons.people_alt_rounded,
      'colors': [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
      'sub': '${_allCustomers.length} total registered',
    },
    {
      'title': 'GST Liability',
      'value': _fmt(_taxLiability()),
      'icon': Icons.receipt_long_rounded,
      'colors': [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
      'sub': 'Gross output tax',
    },
  ];

  Widget _buildStatCard(Map<String, dynamic> stat, {bool compact = false}) {
    final colors = stat['colors'] as List<Color>;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.30), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(stat['icon'] as IconData, color: Colors.white, size: 18),
              ),
              const Icon(Icons.trending_up_rounded, color: Colors.white38, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(stat['title'] as String, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat['value'] as String,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(stat['sub'] as String, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    final stats = _statsData();
    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: stats.indexOf(stat) == 0 ? 0 : 16),
          child: SizedBox(height: 165, child: _buildStatCard(stat)),
        ),
      )).toList(),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final stats = _statsData();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => _buildStatCard(stats[index], compact: true),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _QuickActionButton(icon: Icons.add_rounded, label: 'Invoice', color: const Color(0xFF4F46E5), onTap: () => context.go('/invoices/create')),
          const SizedBox(width: 12),
          _QuickActionButton(icon: Icons.bar_chart_rounded, label: 'Reports', color: const Color(0xFFF59E0B), onTap: () => context.go('/reports')),
          const SizedBox(width: 12),
          _QuickActionButton(icon: Icons.people_rounded, label: 'Customers', color: const Color(0xFF0EA5E9), onTap: () => context.go('/customers')),
          const SizedBox(width: 12),
          _QuickActionButton(icon: Icons.payment_rounded, label: 'Payments', color: const Color(0xFF10B981), onTap: () => context.go('/payments')),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(ThemeData theme) {
    final monthly = _monthlyRevenue();
    final keys = monthly.keys.toList();
    final values = monthly.values.toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final total = values.fold(0.0, (s, v) => s + v);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Revenue Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                    child: const Text('LAST 6 MONTHS', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TOTAL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      Text(_fmt(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal > 0 ? maxVal * 1.3 : 100,
                barGroups: keys.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: monthly[entry.value] ?? 0,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.6),
                            theme.colorScheme.primary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal > 0 ? maxVal * 1.3 : 100,
                          color: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= keys.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            keys[idx],
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '₹${_fmtK(value)}',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                      _fmt(rod.toY),
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsVertical(BuildContext context) {
    final actions = [
      {'icon': Icons.add_rounded, 'label': 'New Invoice', 'sub': 'Create a sales bill', 'color': const Color(0xFF4F46E5), 'route': '/invoices/create'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'sub': 'Sales & GST reports', 'color': const Color(0xFFF59E0B), 'route': '/reports'},
      {'icon': Icons.people_rounded, 'label': 'Customers', 'sub': 'Manage customer ledger', 'color': const Color(0xFF0EA5E9), 'route': '/customers'},
      {'icon': Icons.payment_rounded, 'label': 'Record Payment', 'sub': 'Log incoming payments', 'color': const Color(0xFF10B981), 'route': '/payments'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...actions.map((action) {
            final isLast = actions.last == action;
            return InkWell(
              onTap: () => context.go(action['route'] as String),
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(24))
                  : BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(action['label'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
                          Text(action['sub'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(BuildContext context, ThemeData theme) {
    final recent = _recentInvoices;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.3)),
            TextButton.icon(
              onPressed: () => context.go('/invoices'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('See All', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 12),
                        Text('No recent activity', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 20, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, i) => _InvoiceListTile(invoice: recent[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildLowStockAlert(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFF97316)),
              const SizedBox(width: 8),
              const Text('Low Stock Alert', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF9A3412))),
              const Spacer(),
              Text('${_lowStockProducts.length} Items', style: const TextStyle(color: Color(0xFFC2410C), fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          ..._lowStockProducts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF431407), fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(20)),
                      child: Text('Only ${p.stock}', style: const TextStyle(color: Color(0xFFBE123C), fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceListTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##,###.##', 'en_IN');
    final color = _invoiceStatusColor(invoice.status);
    final initial = (invoice.customerName?.isNotEmpty ?? false)
        ? invoice.customerName![0].toUpperCase()
        : '?';

    return InkWell(
      onTap: () => context.go('/invoices'),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber ?? 'NO-INV',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    invoice.customerName ?? 'Unknown Customer',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${formatter.format(invoice.total ?? 0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.15)),
                  ),
                  child: Text(
                    invoice.status?.toUpperCase() ?? 'DRAFT',
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
          child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}

Color _invoiceStatusColor(String? status) {
  switch (status?.toUpperCase()) {
    case 'PAID': return const Color(0xFF10B981);
    case 'ISSUED': return const Color(0xFF6366F1);
    case 'PARTIAL': return const Color(0xFFF59E0B);
    case 'CANCELLED': return const Color(0xFFEF4444);
    default: return const Color(0xFF94A3B8);
  }
}
