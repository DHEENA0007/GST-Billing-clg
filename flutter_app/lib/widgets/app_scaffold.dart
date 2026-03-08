import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

class AppScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.fab,
    this.actions,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  bool _searchOpen = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;
  List<dynamic> _alerts = [];
  int _unreadCount = 0;
  bool _notifOpen = false;
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    try {
      final data = await _api.get(AppConstants.aiDashboard);
      if (data is Map) {
        final alerts = data['alerts'] as List? ?? [];
        if (mounted) {
          setState(() {
            _alerts = alerts;
            _unreadCount = alerts.where((a) => a is Map && a['is_read'] != true).length;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searchLoading = true);
    try {
      final results = <Map<String, dynamic>>[];
      final lower = q.toLowerCase();

      final futures = await Future.wait([
        _api.get('${AppConstants.invoices}?search=$q').catchError((_) => <dynamic>[]),
        _api.get('${AppConstants.customers}?search=$q').catchError((_) => <dynamic>[]),
        _api.get('${AppConstants.products}?search=$q').catchError((_) => <dynamic>[]),
      ]);

      _extractList(futures[0]).where((inv) {
        if (inv is! Map) return false;
        final num = inv['invoice_number']?.toString() ?? '';
        final cust = inv['customer_name']?.toString() ?? '';
        return num.toLowerCase().contains(lower) || cust.toLowerCase().contains(lower);
      }).forEach((inv) {
        results.add({
          'type': 'Invoice',
          'icon': Icons.receipt_long,
          'title': inv['invoice_number']?.toString() ?? '',
          'sub': inv['customer_name']?.toString() ?? '',
          'route': '/invoices',
        });
      });

      _extractList(futures[1]).where((c) {
        if (c is! Map) return false;
        final name = c['name']?.toString() ?? '';
        final gstin = c['gstin']?.toString() ?? '';
        return name.toLowerCase().contains(lower) || gstin.toLowerCase().contains(lower);
      }).forEach((c) {
        results.add({
          'type': 'Customer',
          'icon': Icons.person,
          'title': c['name']?.toString() ?? '',
          'sub': c['gstin']?.toString() ?? '',
          'route': '/customers',
        });
      });

      _extractList(futures[2]).where((p) {
        if (p is! Map) return false;
        final name = p['name']?.toString() ?? '';
        final hsn = p['hsn_sac']?.toString() ?? '';
        return name.toLowerCase().contains(lower) || hsn.toLowerCase().contains(lower);
      }).forEach((p) {
        results.add({
          'type': 'Product',
          'icon': Icons.inventory_2,
          'title': p['name']?.toString() ?? '',
          'sub': 'HSN: ${p['hsn_sac'] ?? ''}',
          'route': '/products',
        });
      });

      if (mounted) setState(() => _searchResults = results.take(8).toList());
    } catch (_) {}
    if (mounted) setState(() => _searchLoading = false);
  }

  List _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['results'] is List) return raw['results'] as List;
    return [];
  }

  Color _alertColor(String? sev) {
    switch (sev?.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData _alertIcon(String? sev) {
    switch (sev?.toLowerCase()) {
      case 'critical': return Icons.error;
      case 'warning': return Icons.warning;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: _searchOpen ? _buildSearchBar() : Text(widget.title),
        actions: [
          if (!_searchOpen) ...[
            if (widget.actions != null) ...widget.actions!,
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() { _searchOpen = true; _searchResults = []; });
                Future.delayed(const Duration(milliseconds: 100), () => _searchFocus.requestFocus());
              },
              tooltip: 'Search',
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => setState(() => _notifOpen = !_notifOpen),
                  tooltip: 'Notifications',
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() { _searchOpen = false; _searchCtrl.clear(); _searchResults = []; }),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.go('/settings'),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  (auth.user?.username ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _AppDrawer(currentLocation: currentLocation, auth: auth),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_notifOpen || _searchOpen) {
                setState(() { _notifOpen = false; });
              }
            },
            child: widget.body,
          ),
          // Search Results Overlay
          if (_searchOpen && (_searchResults.isNotEmpty || _searchLoading))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 8,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 360),
                  color: Colors.white,
                  child: _searchLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final r = _searchResults[i];
                            return ListTile(
                              leading: Icon(r['icon'] as IconData, color: theme.colorScheme.primary),
                              title: Text(r['title'] as String),
                              subtitle: Text('${r['type']} • ${r['sub']}', style: TextStyle(color: Colors.grey[600])),
                              onTap: () {
                                setState(() { _searchOpen = false; _searchCtrl.clear(); _searchResults = []; });
                                context.go(r['route'] as String);
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          // Notifications Overlay
          if (_notifOpen)
            Positioned(
              top: 0,
              right: 8,
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 320,
                  constraints: const BoxConstraints(maxHeight: 420),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                                if (_unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                    child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ],
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _notifOpen = false);
                                context.go('/ai-insights');
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (_alerts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No alerts', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _alerts.length > 5 ? 5 : _alerts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final a = _alerts[i];
                              if (a is! Map) return const SizedBox.shrink();
                              final sev = a['severity']?.toString() ?? a['type']?.toString();
                              final color = _alertColor(sev);
                              return ListTile(
                                leading: Icon(_alertIcon(sev), color: color, size: 20),
                                title: Text(a['title']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text(a['message']?.toString() ?? '', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                onTap: () {
                                  setState(() => _notifOpen = false);
                                  context.go('/ai-insights');
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.fab,
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      focusNode: _searchFocus,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: const InputDecoration(
        hintText: 'Search invoices, customers, products...',
        hintStyle: TextStyle(color: Colors.white60),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: _onSearch,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final String currentLocation;
  final AuthProvider auth;

  const _AppDrawer({required this.currentLocation, required this.auth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = '${auth.user?.firstName ?? ''} ${auth.user?.lastName ?? ''}'.trim();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            accountName: Text(
              fullName.isNotEmpty ? fullName : (auth.user?.username ?? 'User'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(auth.user?.email ?? '', style: const TextStyle(fontSize: 12)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (auth.user?.username ?? 'U')[0].toUpperCase(),
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            otherAccountsPictures: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Text(auth.user?.role ?? '', style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/dashboard', current: currentLocation),
                _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Invoices', route: '/invoices', current: currentLocation),
                _DrawerItem(icon: Icons.people_outline, label: 'Customers', route: '/customers', current: currentLocation),
                _DrawerItem(icon: Icons.inventory_2_outlined, label: 'Products', route: '/products', current: currentLocation),
                _DrawerItem(icon: Icons.local_shipping_outlined, label: 'Vendors', route: '/vendors', current: currentLocation),
                _DrawerItem(icon: Icons.payment_outlined, label: 'Payments', route: '/payments', current: currentLocation),
                _DrawerItem(icon: Icons.bar_chart_outlined, label: 'Reports', route: '/reports', current: currentLocation),
                _DrawerItem(icon: Icons.auto_awesome_outlined, label: 'AI Insights', route: '/ai-insights', current: currentLocation),
                _DrawerItem(icon: Icons.note_alt_outlined, label: 'Credit/Debit Notes', route: '/credit-debit-notes', current: currentLocation),
                if (auth.isAdmin) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
                  ),
                  _DrawerItem(icon: Icons.history_outlined, label: 'Audit Trail', route: '/audit', current: currentLocation),
                  _DrawerItem(icon: Icons.manage_accounts_outlined, label: 'Team & Roles', route: '/roles', current: currentLocation),
                ],
                const Divider(),
                _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', route: '/settings', current: currentLocation),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String current;

  const _DrawerItem({required this.icon, required this.label, required this.route, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = current == route || (current.startsWith(route) && route != '/dashboard');

    return ListTile(
      leading: Icon(icon, color: isActive ? theme.colorScheme.primary : null),
      title: Text(label, style: TextStyle(color: isActive ? theme.colorScheme.primary : null, fontWeight: isActive ? FontWeight.bold : null)),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        if (!isActive) context.go(route);
      },
    );
  }
}
