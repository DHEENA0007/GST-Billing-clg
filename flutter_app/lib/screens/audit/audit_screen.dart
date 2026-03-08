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
      final params = <String, dynamic>{};
      if (_searchCtrl.text.isNotEmpty) params['search'] = _searchCtrl.text;
      final data = await _api.get(AppConstants.auditLogs, queryParameters: params);
      List items = [];
      if (data is Map && data['results'] != null) items = data['results'];
      else if (data is List) items = data;
      setState(() {
        _logs = items.map((l) => AuditLog.fromJson(l)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _actionColor(String? action) {
    switch (action?.toUpperCase()) {
      case 'CREATE': return Colors.green;
      case 'UPDATE': return Colors.blue;
      case 'DELETE': return Colors.red;
      case 'LOGIN': return Colors.purple;
      case 'LOGOUT': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _actionIcon(String? action) {
    switch (action?.toUpperCase()) {
      case 'CREATE': return Icons.add_circle;
      case 'UPDATE': return Icons.edit;
      case 'DELETE': return Icons.delete;
      case 'LOGIN': return Icons.login;
      case 'LOGOUT': return Icons.logout;
      default: return Icons.history;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '-';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Audit Trail',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by user, action, or details...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _load(); })
                    : null,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_error!),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ]))
                    : _logs.isEmpty
                        ? const Center(child: Text('No audit logs found'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _logs.length,
                              itemBuilder: (context, i) {
                                final log = _logs[i];
                                final color = _actionColor(log.action);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(_actionIcon(log.action), color: color, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      log.action ?? '',
                                                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (log.model != null)
                                                    Text(log.model!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  if (log.objectId != null) ...[
                                                    const SizedBox(width: 4),
                                                    Text('#${log.objectId}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              if (log.user != null)
                                                Text('By: ${log.user}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                              if (log.details != null)
                                                Text(log.details!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatTimestamp(log.timestamp),
                                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                                  ),
                                                  if (log.ipAddress != null) ...[
                                                    const SizedBox(width: 12),
                                                    Icon(Icons.computer, size: 12, color: Colors.grey[400]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      log.ipAddress!,
                                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
