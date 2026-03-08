import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../widgets/app_scaffold.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  Map<String, dynamic> _data = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.get(AppConstants.aiDashboard);
      setState(() {
        _data = data is Map ? Map<String, dynamic>.from(data) : {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAlertRead(dynamic alertId) async {
    try {
      await _api.patch('ai/alerts/$alertId/mark_read/');
      _load();
    } catch (_) {}
  }

  Future<void> _dismissAlert(dynamic alertId) async {
    try {
      await _api.patch('ai/alerts/$alertId/dismiss/');
      _load();
    } catch (_) {}
  }

  String _getHealthGrade(dynamic score) {
    final s = score is num ? score.toDouble() : 0.0;
    if (s >= 90) return 'A+';
    if (s >= 80) return 'A';
    if (s >= 70) return 'B';
    if (s >= 60) return 'C';
    if (s >= 50) return 'D';
    return 'F';
  }

  Color _getHealthColor(dynamic score) {
    final s = score is num ? score.toDouble() : 0.0;
    if (s >= 80) return Colors.green;
    if (s >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _alertColor(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _alertIcon(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return Icons.error;
      case 'WARNING':
        return Icons.warning_amber;
      case 'INFO':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _impactColor(String? impact) {
    switch (impact?.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.amber;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _riskColor(String? risk) {
    switch (risk?.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.amber;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'inventory':
        return Icons.inventory;
      case 'finance':
        return Icons.account_balance;
      case 'sales':
        return Icons.trending_up;
      case 'customer':
        return Icons.people;
      case 'tax':
        return Icons.receipt_long;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AI Insights',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
      ],
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
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildMetricsRow(),
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: TabBar(
                        controller: _tabController,
                        labelColor:
                            Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor:
                            Theme.of(context).colorScheme.primary,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: 'Health & Factors'),
                          Tab(text: 'Alerts'),
                          Tab(text: 'Recommendations'),
                          Tab(text: 'Predictions'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHealthTab(),
                          _buildAlertsTab(),
                          _buildRecommendationsTab(),
                          _buildPredictionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMetricsRow() {
    final predictions = _data['predictions'];
    final pMap = predictions is Map
        ? Map<String, dynamic>.from(predictions)
        : <String, dynamic>{};
    final healthScore = pMap['business_health_score'] ?? _data['health_score'] ?? 0;
    final alerts = _data['alerts'] as List? ?? [];
    final recommendations = _data['recommendations'] as List? ?? [];
    final revForecast = pMap['revenue_forecast'];
    final criticalCount =
        alerts.where((a) => a is Map && (a['severity']?.toString().toUpperCase() == 'CRITICAL')).length;
    final warningCount =
        alerts.where((a) => a is Map && (a['severity']?.toString().toUpperCase() == 'WARNING')).length;
    final infoCount =
        alerts.where((a) => a is Map && (a['severity']?.toString().toUpperCase() == 'INFO')).length;

    String forecastText = '-';
    String confidenceText = '';
    if (revForecast is Map) {
      final trend = revForecast['trend']?.toString() ?? '';
      final confidence = revForecast['confidence'];
      forecastText = trend.isNotEmpty ? trend : '-';
      if (confidence != null) confidenceText = '$confidence%';
    }

    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: 'Health Score',
              value: '${healthScore.toString()}/100',
              color: _getHealthColor(healthScore),
              icon: Icons.favorite,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricCard(
              title: 'Alerts',
              value:
                  '${criticalCount}C / ${warningCount}W / ${infoCount}I',
              color: criticalCount > 0 ? Colors.red : Colors.orange,
              icon: Icons.notifications_active,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricCard(
              title: 'Revenue Forecast',
              value: forecastText,
              subtitle: confidenceText,
              color: Colors.green,
              icon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricCard(
              title: 'Recommendations',
              value: recommendations.length.toString(),
              color: Colors.indigo,
              icon: Icons.lightbulb,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    final predictions = _data['predictions'];
    final pMap = predictions is Map
        ? Map<String, dynamic>.from(predictions)
        : <String, dynamic>{};
    final healthScore =
        pMap['business_health_score'] ?? _data['health_score'] ?? 0;
    final grade = _getHealthGrade(healthScore);
    final color = _getHealthColor(healthScore);
    final scoreVal =
        healthScore is num ? healthScore.toDouble() : 0.0;
    final factors = pMap['factors'] as List? ?? _data['factors'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 4),
                          ),
                          child: Center(
                            child: Text(
                              grade,
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Business Health Score',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: scoreVal / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 10,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${scoreVal.toStringAsFixed(0)}/100',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (factors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Contributing Factors',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: factors.map((f) {
                      if (f is! Map) return const SizedBox.shrink();
                      final name = f['name']?.toString() ?? f['factor']?.toString() ?? '';
                      final score = f['score'] ?? f['value'] ?? 0;
                      final scoreDouble =
                          score is num ? score.toDouble() : 0.0;
                      final fColor = _getHealthColor(scoreDouble);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Text(
                                    '${scoreDouble.toStringAsFixed(0)}/100',
                                    style: TextStyle(
                                        color: fColor,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: scoreDouble / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(fColor),
                              minHeight: 6,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    final alerts = _data['alerts'] as List? ?? [];
    if (alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No alerts at this time'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, i) {
          final alert = alerts[i];
          if (alert is! Map) return const SizedBox.shrink();
          final severity = alert['severity']?.toString() ?? alert['type']?.toString();
          final color = _alertColor(severity);
          final id = alert['id'];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_alertIcon(severity), color: color, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alert['title']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          severity?.toUpperCase() ?? '',
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (alert['message'] != null) ...[
                    const SizedBox(height: 8),
                    Text(alert['message'].toString(),
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 13)),
                  ],
                  if (alert['action'] != null) ...[
                    const SizedBox(height: 6),
                    Text(alert['action'].toString(),
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                  ],
                  if (id != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _markAlertRead(id),
                          icon: const Icon(Icons.done, size: 16),
                          label: const Text('Mark Read'),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              textStyle:
                                  const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _dismissAlert(id),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Dismiss'),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              textStyle:
                                  const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    final recs = _data['recommendations'] as List? ?? [];
    if (recs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No recommendations at this time'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recs.length,
        itemBuilder: (context, i) {
          final rec = recs[i];
          if (rec is! Map) return const SizedBox.shrink();
          final category = rec['category']?.toString();
          final impact = rec['impact']?.toString() ?? rec['impact_level']?.toString();
          final title = rec['title']?.toString() ?? rec['recommendation']?.toString() ?? '';
          final message = rec['message']?.toString() ?? rec['text']?.toString() ?? '';
          final impactColor = _impactColor(impact);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_categoryIcon(category),
                        color: Colors.indigo, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (category != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(category,
                                    style: const TextStyle(
                                        color: Colors.indigo,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (impact != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      impactColor.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(impact.toUpperCase(),
                                    style: TextStyle(
                                        color: impactColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (title.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(message,
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPredictionsTab() {
    final predictions = _data['predictions'];
    final pMap = predictions is Map
        ? Map<String, dynamic>.from(predictions)
        : <String, dynamic>{};
    final demandForecast =
        pMap['demand_forecast'] as List? ?? [];
    final paymentPrediction =
        pMap['payment_prediction'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Demand Forecast',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: demandForecast.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No demand forecast data available'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Predicted/Month')),
                          DataColumn(label: Text('Trend')),
                          DataColumn(label: Text('Stock')),
                          DataColumn(label: Text('Reorder Urgency')),
                        ],
                        rows: demandForecast.map((item) {
                          if (item is! Map) {
                            return const DataRow(cells: []);
                          }
                          final trend =
                              item['trend']?.toString() ?? '';
                          IconData trendIcon = Icons.remove;
                          Color trendColor = Colors.grey;
                          if (trend.toLowerCase() == 'up') {
                            trendIcon = Icons.trending_up;
                            trendColor = Colors.green;
                          } else if (trend.toLowerCase() == 'down') {
                            trendIcon = Icons.trending_down;
                            trendColor = Colors.red;
                          }
                          final urgency =
                              item['reorder_urgency']?.toString() ??
                                  item['urgency']?.toString() ??
                                  '';
                          return DataRow(cells: [
                            DataCell(Text(
                                item['product']?.toString() ?? '')),
                            DataCell(Text(item['predicted_monthly']
                                    ?.toString() ??
                                item['predicted']?.toString() ??
                                '-')),
                            DataCell(Icon(trendIcon,
                                color: trendColor, size: 18)),
                            DataCell(Text(
                                item['stock']?.toString() ?? '-')),
                            DataCell(_buildUrgencyChip(urgency)),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Text('Payment Behavior',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: paymentPrediction.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'No payment behavior data available'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Customer')),
                          DataColumn(label: Text('Avg Delay Days')),
                          DataColumn(label: Text('Risk Level')),
                        ],
                        rows: paymentPrediction.map((item) {
                          if (item is! Map) {
                            return const DataRow(cells: []);
                          }
                          final risk = item['risk_level']?.toString() ??
                              item['risk']?.toString() ??
                              '';
                          final rColor = _riskColor(risk);
                          return DataRow(cells: [
                            DataCell(Text(
                                item['customer']?.toString() ?? '')),
                            DataCell(Text(item['avg_delay_days']
                                    ?.toString() ??
                                '-')),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: rColor.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Text(risk.toUpperCase(),
                                  style: TextStyle(
                                      color: rColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    Color color;
    switch (urgency.toUpperCase()) {
      case 'HIGH':
        color = Colors.red;
        break;
      case 'MEDIUM':
        color = Colors.amber;
        break;
      case 'LOW':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(urgency.isEmpty ? '-' : urgency.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color),
              overflow: TextOverflow.ellipsis),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
