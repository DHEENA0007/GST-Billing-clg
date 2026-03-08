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
    return AppScaffold(
      title: 'Reports',
      body: Column(
        children: [
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(_startDate),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(_endDate),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loadCurrentTab,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                return _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _ReportContent(data: _data, tabName: tab);
              }).toList(),
            ),
          ),
        ],
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
      return Center(child: Text(data['error'] as String));
    }
    if (data.isEmpty) {
      return const Center(child: Text('No data available for selected period'));
    }

    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tabName Report',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            if (entry.value is Map) {
              return _buildSection(context, entry.key, entry.value as Map, formatter);
            } else if (entry.value is List) {
              return _buildListSection(context, entry.key, entry.value as List, formatter);
            } else {
              return _buildKVRow(entry.key, entry.value, formatter);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildKVRow(String key, dynamic value, NumberFormat formatter) {
    String displayKey = key.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');

    String displayValue;
    if (value is num) {
      displayValue = '₹${formatter.format(value)}';
    } else {
      displayValue = value?.toString() ?? '-';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(displayKey, style: TextStyle(color: Colors.grey[700])),
          Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Map map, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const Divider(),
            ...map.entries.map((e) => _buildKVRow(e.key, e.value, formatter)),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(BuildContext context, String title, List list, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const Divider(),
            if (list.isEmpty)
              const Text('No data')
            else
              ...list.take(20).map((item) {
                if (item is Map) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        ...item.entries.map((e) => _buildKVRow(e.key, e.value, formatter)),
                        const Divider(height: 8),
                      ],
                    ),
                  );
                }
                return Text(item.toString());
              }),
          ],
        ),
      ),
    );
  }
}
