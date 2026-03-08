import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String? _error;
  String _filterAction = 'ALL';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(AppConstants.auditLogs);
      List items = [];
      if (data is Map && data['results'] != null) items = data['results'];
      else if (data is List) items = data;
      setState(() {
        _logs = items.map((l) => AuditLog.fromJson(l)).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<String> get _allActions {
    return _logs.map((l) => l.action ?? '').toSet().toList()
      ..sort()
      ..removeWhere((s) => s.isEmpty);
  }

  List<AuditLog> get _filteredLogs {
    final q = _searchCtrl.text.toLowerCase();
    return _logs.where((l) {
      final matchAction = _filterAction == 'ALL' || l.action == _filterAction;
      final matchSearch = q.isEmpty ||
          (l.user ?? '').toLowerCase().contains(q) ||
          (l.action ?? '').toLowerCase().contains(q) ||
          (l.details ?? '').toLowerCase().contains(q) ||
          (l.model ?? '').toLowerCase().contains(q);
      return matchAction && matchSearch;
    }).toList();
  }

  Color _actionColor(String? action) {
    final a = action?.toUpperCase() ?? '';
    if (a.contains('CREATE') || a.contains('ADD')) return Colors.green;
    if (a.contains('UPDATE') || a.contains('EDIT')) return Colors.blue;
    if (a.contains('DELETE') || a.contains('CANCEL') || a.contains('REMOVE')) return Colors.red;
    if (a.contains('LOGIN')) return Colors.indigo;
    return Colors.grey;
  }

  IconData _actionIcon(String? action) {
    final a = action?.toUpperCase() ?? '';
    if (a.contains('CREATE') || a.contains('ADD')) return Icons.add_circle_outline;
    if (a.contains('UPDATE') || a.contains('EDIT')) return Icons.edit_note;
    if (a.contains('DELETE') || a.contains('CANCEL') || a.contains('REMOVE')) return Icons.delete_outline;
    if (a.contains('LOGIN')) return Icons.login;
    if (a.contains('LOGOUT')) return Icons.logout;
    return Icons.history;
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '-';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredLogs;
    final actions = _allActions;

    return AppScaffold(
      title: 'Activity Logs',
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Search operations or users...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterAction,
                            isExpanded: true,
                            dropdownColor: theme.colorScheme.primary,
                            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                            items: [
                              const DropdownMenuItem(value: 'ALL', child: Text('ALL ACTIONS')),
                              ...actions.map((a) => DropdownMenuItem(value: a, child: Text(a.toUpperCase()))),
                            ],
                            onChanged: (v) => setState(() => _filterAction = v!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _load,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _isLoading && _logs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => _AuditLogCard(log: filtered[index]),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.security_update_warning_rounded, size: 48, color: Colors.red[400]),
          ),
          const SizedBox(height: 24),
          Text(_error ?? 'Network conflict', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('RETRY SYNC')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.history_toggle_off_rounded, size: 64, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text('Clear Audit History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const Text('No security events matched your criteria.', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLog log;
  const _AuditLogCard({required this.log});

  Color _actionColor(String? action) {
    if (action == null) return const Color(0xFF64748B);
    final a = action.toUpperCase();
    if (a.contains('CREATE') || a.contains('ADD')) return const Color(0xFF10B981);
    if (a.contains('UPDATE') || a.contains('EDIT')) return const Color(0xFF3B82F6);
    if (a.contains('DELETE')) return const Color(0xFFEF4444);
    if (a.contains('LOGIN')) return const Color(0xFF6366F1);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);
    final dt = log.timestamp != null ? DateTime.parse(log.timestamp!).toLocal() : DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(dt);
    final dateStr = DateFormat('dd MMM').format(dt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.horizontal(right: Radius.circular(4))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          log.action?.toUpperCase() ?? 'ACTION',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
                        ),
                        const Spacer(),
                        Text(
                          '$dateStr, $timeStr',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.details ?? 'Security operation performed',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(log.user ?? 'System', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.layers_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(log.model ?? 'Entity', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

