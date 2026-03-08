import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/app_scaffold.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  final List<String> _tabs = [
    'Sales',
    'Purchase',
    'GST Summary',
    'P&L',
    'Outstanding',
    'Stock',
    'Tax Liability',
    'GSTR-1',
    'GSTR-3B',
  ];

  String _startDate = '';
  String _endDate = '';
  Map<String, dynamic> _data = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    _startDate = DateFormat('yyyy-MM-dd').format(startOfMonth);
    _endDate = DateFormat('yyyy-MM-dd').format(now);
    _loadCurrentTab();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentEndpoint {
    switch (_tabController.index) {
      case 0: return AppConstants.salesReport;
      case 1: return AppConstants.purchaseReport;
      case 2: return AppConstants.gstSummary;
      case 3: return AppConstants.profitLoss;
      case 4: return AppConstants.customerOutstanding;
      case 5: return AppConstants.stockReport;
      case 6: return AppConstants.taxLiability;
      case 7: return AppConstants.gstr1;
      case 8: return AppConstants.gstr3b;
      default: return AppConstants.salesReport;
    }
  }

  Future<void> _loadCurrentTab() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.get(_currentEndpoint, queryParameters: {
        'start_date': _startDate,
        'end_date': _endDate,
      });
      setState(() {
        _data = result is Map ? Map<String, dynamic>.from(result) : {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _data = {'error': e.toString()}; _isLoading = false; });
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
      _loadCurrentTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Business Reports',
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
          ),
          onPressed: _loadCurrentTab,
          tooltip: 'Refresh Report',
        ),
      ],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DateInputField(
                    label: 'FROM DATE',
                    value: _startDate,
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateInputField(
                    label: 'TO DATE',
                    value: _endDate,
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _tabs.map((t) => Tab(text: t.toUpperCase())).toList(),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 4, color: theme.colorScheme.primary),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  return _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(strokeWidth: 3),
                              const SizedBox(height: 16),
                              Text('Generating $tab Report...', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : _ReportContent(data: _data, tabName: tab);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateInputField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateInputField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String tabName;

  const _ReportContent({required this.data, required this.tabName});

  @override
  Widget build(BuildContext context) {
    if (data.containsKey('error')) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text('Oops! Analysis Interrupted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
              child: Text(data['error'] as String, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      );
    }
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.analytics_outlined, size: 64, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 24),
            const Text('No Data Captured', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const Text('There are no records for the selected period.', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tabName.toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8)),
              child: Text('FINANCIAL ANALYSIS', style: TextStyle(color: Colors.indigo[700], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...data.entries.map((entry) {
          if (entry.value is Map) {
            return _buildSection(context, entry.key, entry.value as Map, formatter);
          } else if (entry.value is List) {
            return _buildListSection(context, entry.key, entry.value as List, formatter);
          } else {
            return _buildGenericCard(entry.key, entry.value, formatter);
          }
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGenericCard(String key, dynamic value, NumberFormat formatter) {
    String displayKey = key.replaceAll('_', ' ').toUpperCase();
    bool isCurrency = value is num;
    String displayValue = isCurrency ? '₹${formatter.format(value)}' : value?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(displayKey, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          Text(
            displayValue,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isCurrency ? const Color(0xFF4F46E5) : const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Map map, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.layers_rounded, size: 16, color: Colors.indigo[600]),
                ),
                const SizedBox(width: 12),
                Text(
                  title.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B), letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...map.entries.map((e) {
            final isLast = map.entries.last.key == e.key;
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, isLast ? 24 : 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                  Text(
                    e.value is num ? '₹${formatter.format(e.value)}' : e.value?.toString() ?? '-',
                    style: TextStyle(fontWeight: FontWeight.w900, color: e.value is num ? const Color(0xFF4F46E5) : const Color(0xFF475569)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListSection(BuildContext context, String title, List list, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.lightBlue[50], borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.list_alt_rounded, size: 16, color: Colors.lightBlue[600]),
                ),
                const SizedBox(width: 12),
                Text(
                  title.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B), letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          if (list.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: Text('No entries records found', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
          else
            ...list.take(20).map((item) {
              final idx = list.indexOf(item);
              final isLast = idx == list.length - 1 || idx == 19;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: idx % 2 != 0 ? const Color(0xFFF8FAFC) : Colors.white,
                  borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(28)) : null,
                ),
                child: item is Map
                    ? Column(
                        children: item.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w800)),
                              Text(e.value is num ? '₹${formatter.format(e.value)}' : e.value?.toString() ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                            ],
                          ),
                        )).toList(),
                      )
                    : Text(item.toString()),
              );
            }),
        ],
      ),
    );
  }
}
