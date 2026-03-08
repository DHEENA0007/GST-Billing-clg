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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Dashboard',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadDashboard,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${auth.user?.username ?? 'User'}!',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy')
                              .format(DateTime.now()),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildRevenueChart(),
                        const SizedBox(height: 24),
                        _buildRecentInvoices(context),
                        if (_lowStockProducts.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildLowStockAlert(),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Revenue Collected',
        'value': _fmt(_revenueCollected()),
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'title': 'Pending Receivables',
        'value': _fmt(_pendingReceivables()),
        'icon': Icons.pending_actions,
        'color': Colors.orange,
      },
      {
        'title': 'Active Customers',
        'value': _activeCustomers().toString(),
        'icon': Icons.people,
        'color': Colors.blue,
      },
      {
        'title': 'Tax Liability (GST)',
        'value': _fmt(_taxLiability()),
        'icon': Icons.account_balance,
        'color': Colors.purple,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = constraints.maxWidth;
        final crossCount = innerWidth > 600 ? 4 : 2;
        final itemWidth = (innerWidth - ((crossCount - 1) * 12)) / crossCount;
        final aspect = itemWidth / 90.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: aspect,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        stat['title'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(stat['icon'] as IconData,
                        color: stat['color'] as Color, size: 20),
                  ],
                ),
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'New Invoice',
                color: Colors.indigo,
                onTap: () => context.go('/invoices/create'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.bar_chart,
                label: 'View Reports',
                color: Colors.orange,
                onTap: () => context.go('/reports'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.people,
                label: 'Customers',
                color: Colors.blue,
                onTap: () => context.go('/customers'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.payment,
                label: 'Payments',
                color: Colors.green,
                onTap: () => context.go('/payments'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final monthly = _monthlyRevenue();
    final keys = monthly.keys.toList();
    final values = monthly.values.toList();
    final maxVal =
        values.fold<double>(1.0, (prev, v) => v > prev ? v : prev);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenue - Last 6 Months',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.2,
                  barGroups: List.generate(keys.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= keys.length) {
                            return const Text('');
                          }
                          return Text(keys[idx],
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoices(BuildContext context) {
    final recent = _recentInvoices;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Invoices',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/invoices'),
                  child: const Text('View All'),
                ),
              ],
            ),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child:
                    Center(child: Text('No invoices yet')),
              )
            else
              ...recent.map((inv) => _InvoiceListTile(invoice: inv)),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Card(
      color: Colors.orange[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Low Stock Alert',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800])),
              ],
            ),
            const SizedBox(height: 12),
            ..._lowStockProducts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stock: ${p.stock}',
                          style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

Color _invoiceStatusColor(String? status) {
  switch (status?.toUpperCase()) {
    case 'PAID':
      return Colors.green;
    case 'ISSUED':
      return Colors.blue;
    case 'PARTIAL':
      return Colors.amber;
    case 'CANCELLED':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class _InvoiceListTile extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceListTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##,###.##', 'en_IN');
    final color = _invoiceStatusColor(invoice.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.receipt, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.invoiceNumber ?? '',
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                Text(invoice.customerName ?? '',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${formatter.format(invoice.total ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invoice.status ?? '',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
