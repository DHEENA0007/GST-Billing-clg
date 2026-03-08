import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;
  int? _editingUserId;
  String? _editingRole;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(AppConstants.roles);
      List items = [];
      if (data is Map && data['results'] != null) {
        items = data['results'];
      } else if (data is List) {
        items = data;
      }
      setState(() {
        _users = items.map((u) => UserModel.fromJson(u)).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filteredUsers {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      return (u.username?.toLowerCase().contains(q) ?? false) ||
          (u.firstName?.toLowerCase().contains(q) ?? false) ||
          (u.lastName?.toLowerCase().contains(q) ?? false) ||
          (u.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  int _countRole(String role) =>
      _users.where((u) => u.role?.toUpperCase() == role.toUpperCase()).length;

  Future<void> _saveRole(UserModel user) async {
    if (_editingRole == null) return;
    try {
      await _api.patch('${AppConstants.roles}${user.id}/',
          data: {'role': _editingRole});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role updated'),
              backgroundColor: Colors.green),
        );
        setState(() {
          _editingUserId = null;
          _editingRole = null;
        });
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete "${user.username}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('${AppConstants.roles}${user.id}/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User deleted'),
              backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddUser() {
    showDialog(
      context: context,
      builder: (ctx) => _AddUserDialog(
        onSave: (data) async {
          await _api.post(AppConstants.roles, data: data);
          if (mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('User added successfully'),
                  backgroundColor: Colors.green),
            );
            _load();
          }
        },
      ),
    );
  }

  Color _roleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'ACCOUNTANT':
        return Colors.blue;
      case 'SALES':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return AppScaffold(
        title: 'Team & Roles',
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('403 - Access Denied',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                  const SizedBox(height: 8),
                  const Text(
                      'You do not have permission to manage roles.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final filtered = _filteredUsers;

    return AppScaffold(
      title: 'Team & Roles',
      fab: FloatingActionButton.extended(
        onPressed: _showAddUser,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role summary cards
                        Row(
                          children: [
                            Expanded(
                              child: _RoleSummaryCard(
                                  role: 'ADMIN',
                                  count: _countRole('ADMIN'),
                                  color: Colors.purple),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RoleSummaryCard(
                                  role: 'ACCOUNTANT',
                                  count: _countRole('ACCOUNTANT'),
                                  color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RoleSummaryCard(
                                  role: 'SALES',
                                  count: _countRole('SALES'),
                                  color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Search bar
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText:
                                'Search by username, name or email...',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    })
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        if (filtered.isEmpty)
                          const Center(child: Text('No users found'))
                        else
                          ...filtered.map((u) {
                            final isCurrentUser =
                                u.id == auth.user?.id;
                            final isEditing = _editingUserId == u.id;
                            final roleColor = _roleColor(u.role);

                            return Card(
                              margin:
                                  const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      backgroundColor:
                                          roleColor.withOpacity(0.15),
                                      child: Text(
                                        (u.username ?? 'U')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: roleColor,
                                            fontWeight:
                                                FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                u.username ?? '-',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.indigo
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(8),
                                                  ),
                                                  child: const Text('You',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.indigo,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if ((u.firstName ?? '').isNotEmpty ||
                                              (u.lastName ?? '').isNotEmpty)
                                            Text(
                                              '${u.firstName ?? ''} ${u.lastName ?? ''}'
                                                  .trim(),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                          if ((u.email ?? '').isNotEmpty)
                                            Text(u.email!,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600])),
                                          if ((u.phone ?? '').isNotEmpty)
                                            Text(u.phone!,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600])),
                                          const SizedBox(height: 8),
                                          // Role editing
                                          if (isEditing) ...[
                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      DropdownButtonFormField<
                                                          String>(
                                                    value: _editingRole,
                                                    decoration:
                                                        const InputDecoration(
                                                            border:
                                                                OutlineInputBorder(),
                                                            contentPadding:
                                                                EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            8)),
                                                    items: [
                                                      'ADMIN',
                                                      'ACCOUNTANT',
                                                      'SALES'
                                                    ]
                                                        .map((r) =>
                                                            DropdownMenuItem(
                                                                value: r,
                                                                child:
                                                                    Text(r)))
                                                        .toList(),
                                                    onChanged: (v) =>
                                                        setState(() =>
                                                            _editingRole = v),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _saveRole(u),
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                          backgroundColor:
                                                              Colors.green,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12)),
                                                  child: const Text('Save',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white)),
                                                ),
                                                const SizedBox(width: 4),
                                                OutlinedButton(
                                                  onPressed: () =>
                                                      setState(() {
                                                    _editingUserId = null;
                                                    _editingRole = null;
                                                  }),
                                                  child: const Text(
                                                      'Cancel'),
                                                ),
                                              ],
                                            ),
                                          ] else ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: roleColor
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                              ),
                                              child: Text(
                                                u.role ?? '-',
                                                style: TextStyle(
                                                    color: roleColor,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Actions
                                    if (!isCurrentUser && !isEditing)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue,
                                                size: 20),
                                            tooltip: 'Edit Role',
                                            onPressed: () => setState(() {
                                              _editingUserId = u.id;
                                              _editingRole = u.role;
                                            }),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20),
                                            tooltip: 'Delete',
                                            onPressed: () =>
                                                _deleteUser(u),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _RoleSummaryCard extends StatelessWidget {
  final String role;
  final int count;
  final Color color;

  const _RoleSummaryCard(
      {required this.role, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(role,
                style:
                    TextStyle(fontSize: 12, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _AddUserDialog({required this.onSave});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'SALES';
  bool _obscure = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add User'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Username *',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    DropdownMenuItem(
                        value: 'ACCOUNTANT', child: Text('ACCOUNTANT')),
                    DropdownMenuItem(value: 'SALES', child: Text('SALES')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);
                  try {
                    await widget.onSave({
                      'username': _usernameCtrl.text,
                      'password': _passwordCtrl.text,
                      'email': _emailCtrl.text,
                      'first_name': _firstNameCtrl.text,
                      'last_name': _lastNameCtrl.text,
                      'phone': _phoneCtrl.text,
                      'role': _role,
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red));
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add User'),
        ),
      ],
    );
  }
}
