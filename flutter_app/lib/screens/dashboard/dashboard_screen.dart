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
    final theme = Theme.of(context);

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(auth, theme),
                        const SizedBox(height: 28),
                        _buildStatsGrid(theme),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, 'Quick Actions'),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 32),
                        _buildRevenueAnalytics(theme),
                        const SizedBox(height: 32),
                        _buildRecentInvoices(context, theme),
                        if (_lowStockProducts.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildLowStockAlert(theme),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
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
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(
            (auth.user?.username ?? 'U')[0].toUpperCase(),
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${auth.user?.username ?? 'User'}!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final stats = [
      {
        'title': 'Revenue',
        'value': _fmt(_revenueCollected()),
        'icon': Icons.account_balance_wallet_rounded,
        'colors': [const Color(0xFF6366F1), const Color(0xFF818CF8)],
        'trend': '+12.5%',
      },
      {
        'title': 'Pending',
        'value': _fmt(_pendingReceivables()),
        'icon': Icons.hourglass_empty_rounded,
        'colors': [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
        'trend': '-2.1%',
      },
      {
        'title': 'Customers',
        'value': _activeCustomers().toString(),
        'icon': Icons.group_rounded,
        'colors': [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
        'trend': '+4',
      },
      {
        'title': 'GST Liability',
        'value': _fmt(_taxLiability()),
        'icon': Icons.receipt_long_rounded,
        'colors': [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
        'trend': 'Tax',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final colors = stat['colors'] as List<Color>;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: colors[0].withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(16),
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
                    child: Icon(stat['icon'] as IconData, color: Colors.white, size: 20),
                  ),
                  Text(
                    stat['trend'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat['title'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  FittedBox(
                    child: Text(
                      stat['value'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _buildRevenueAnalytics(ThemeData theme) {
    final monthly = _monthlyRevenue();
    final data = monthly.entries.map((e) => PieChartSectionData(
          value: e.value > 0 ? e.value : 0.1,
          title: '',
          color: theme.colorScheme.primary.withOpacity(0.2 + (monthly.keys.toList().indexOf(e.key) * 0.15)),
          radius: 20,
          showTitle: false,
        )).toList();

    final total = monthly.values.fold(0.0, (s, v) => s + v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(context, 'Revenue Analytics'),
                const Text('Last 6 Months', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PieChart(PieChartData(sections: data, centerSpaceRadius: 60, sectionsSpace: 4)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOTAL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(
                          _fmt(total),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Custom Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: monthly.keys.map((k) {
                final idx = monthly.keys.toList().indexOf(k);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2 + (idx * 0.15)), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(k, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
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
            _buildSectionHeader(context, 'Recent Invoices'),
            TextButton(
              onPressed: () => context.go('/invoices'),
              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: recent.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No recent activity', style: TextStyle(color: Colors.grey))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
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
    final initial = (invoice.customerName?.isNotEmpty ?? false) ? invoice.customerName![0].toUpperCase() : 'U';

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber ?? 'NO-INV',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    invoice.customerName ?? 'Unknown Customer',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${formatter.format(invoice.total ?? 0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    invoice.status?.toUpperCase() ?? 'DRAFT',
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
