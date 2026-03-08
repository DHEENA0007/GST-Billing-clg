import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _error;

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
      final data = await _api.get(AppConstants.customers);
      List items = [];
      if (data is Map && data['results'] != null) {
        items = data['results'];
      } else if (data is List) {
        items = data;
      }
      setState(() {
        _customers = items.map((c) => Customer.fromJson(c)).toList();
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

  List<Customer> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers
        .where((c) =>
            (c.name?.toLowerCase().contains(q) ?? false) ||
            (c.gstin?.toLowerCase().contains(q) ?? false) ||
            (c.email?.toLowerCase().contains(q) ?? false) ||
            (c.phone?.contains(q) ?? false))
        .toList();
  }

  Future<void> _delete(Customer c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${c.name}"? This action cannot be undone.'),
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
      await _api.delete('${AppConstants.customers}${c.id}/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Customer deleted'),
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

  void _showForm({Customer? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerDialog(
        api: _api,
        customer: existing,
        onSave: (data) async {
          try {
            if (existing != null) {
              await _api.put(
                  '${AppConstants.customers}${existing.id}/',
                  data: data);
            } else {
              await _api.post(AppConstants.customers, data: data);
            }
            if (mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(existing != null
                    ? 'Customer updated'
                    : 'Customer added'),
                backgroundColor: Colors.green,
              ));
              _load();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  String _stateLabel(String? code) {
    if (code == null) return '';
    final found = IndianStates.states.firstWhere(
      (s) => s['code'] == code,
      orElse: () => {'code': code, 'name': code},
    );
    return '${found['code']} - ${found['name']}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final isWide = MediaQuery.of(context).size.width > 600;

    return AppScaffold(
      title: 'Customers',
      fab: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('NEW CUSTOMER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Search by name, GSTIN or phone...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(20),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 2 : 1,
                                  childAspectRatio: isWide ? 2.4 : 1.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  return _CustomerCard(
                                    customer: filtered[i],
                                    stateLabel: _stateLabel(filtered[i].stateCode),
                                    onEdit: () => _showForm(existing: filtered[i]),
                                    onDelete: () => _delete(filtered[i]),
                                  );
                                },
                              ),
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
            child: Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red[400]),
          ),
          const SizedBox(height: 16),
          Text(_error ?? 'Connection failed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('RETRY')),
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
            child: const Icon(Icons.people_alt_rounded, size: 64, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text('No Customers Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const Text('Your customer database will appear here.', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final String stateLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.stateLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(
                    (customer.name ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name ?? 'Unnamed Customer',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if ((customer.gstin ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFDCFCE7))),
                          child: Text(customer.gstin!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D), letterSpacing: 0.5)),
                        )
                      else
                        const Text('NO GSTIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 20),
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 20),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Divider(height: 24, color: Color(0xFFF8FAFC)),
            Row(
              children: [
                _StatusItem(icon: Icons.phone_rounded, label: customer.phone ?? 'No phone'),
                const SizedBox(width: 16),
                Expanded(child: _StatusItem(icon: Icons.location_on_rounded, label: stateLabel.split('-').last.trim())),
              ],
            ),
            const SizedBox(height: 8),
            _StatusItem(icon: Icons.alternate_email_rounded, label: (customer.email ?? '').isEmpty ? 'No email registered' : customer.email!),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatusItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CustomerDialog extends StatefulWidget {
  final ApiService api;
  final Customer? customer;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _CustomerDialog({required this.api, this.customer, required this.onSave});

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _gstinCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _shippingCtrl;
  String? _stateCode;
  bool _isSaving = false;
  String? _gstinValidationMsg;
  bool _gstinValidating = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _gstinCtrl = TextEditingController(text: c?.gstin ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _shippingCtrl = TextEditingController(text: c?.shippingAddress ?? '');
    _stateCode = c?.stateCode ?? '33'; // Default to Tamil Nadu or similar
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gstinCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _shippingCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateGstin() async {
    final gstin = _gstinCtrl.text.trim();
    if (gstin.isEmpty) return;
    setState(() {
      _gstinValidating = true;
      _gstinValidationMsg = null;
    });
    try {
      final result = await widget.api.post('${AppConstants.customers}validate_gstin/', data: {'gstin': gstin});
      setState(() {
        _gstinValidationMsg = result is Map && result['valid'] == true ? 'Verified GSTIN' : 'Invalid GSTIN';
        _gstinValidating = false;
      });
    } catch (_) {
      setState(() {
        _gstinValidationMsg = 'Server Unreachable';
        _gstinValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.customer != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Styled Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEdit ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)] : [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                    child: Icon(isEdit ? Icons.person_search_rounded : Icons.person_add_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'UPDATE ENTITY' : 'ESTABLISH NEW ENTITY',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                        ),
                        Text(
                          isEdit ? (widget.customer?.name ?? 'Customer') : 'Relationship Entry',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('ENTITY INFORMATION'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        decoration: _inputDecoration('Business / Customer Name *', Icons.business_rounded),
                        validator: (v) => v == null || v.isEmpty ? 'Entity name identifier required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _gstinCtrl,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 1),
                              decoration: _inputDecoration('GSTIN (Optional)', Icons.verified_user_rounded).copyWith(
                                suffixIcon: _gstinValidating 
                                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                  : (_gstinValidationMsg == 'Verified GSTIN' ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null),
                              ),
                              maxLength: 15,
                              onChanged: (_) => setState(() => _gstinValidationMsg = null),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _gstinValidating ? null : _validateGstin,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                              ),
                              child: const Text('VERIFY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                      if (_gstinValidationMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                _gstinValidationMsg == 'Verified GSTIN' ? Icons.check_circle_rounded : Icons.error_rounded,
                                size: 14,
                                color: _gstinValidationMsg == 'Verified GSTIN' ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _gstinValidationMsg!,
                                style: TextStyle(color: _gstinValidationMsg == 'Verified GSTIN' ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                              decoration: _inputDecoration('Phone *', Icons.phone_rounded),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _stateCode,
                              dropdownColor: Colors.white,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13),
                              decoration: _inputDecoration('State Code *', Icons.map_rounded),
                              items: IndianStates.states.map((s) => DropdownMenuItem(value: s['code'], child: Text('${s['code']} - ${s['name']}'))).toList(),
                              onChanged: (v) => setState(() => _stateCode = v),
                              validator: (v) => v == null ? 'Selection required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        decoration: _inputDecoration('Electronic Mail', Icons.alternate_email_rounded),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionLabel('LOGISTICAL DETAILS'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 13),
                        decoration: _inputDecoration('Billing Address *', Icons.location_on_rounded),
                        validator: (v) => v == null || v.isEmpty ? 'Billing physical address required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shippingCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 13),
                        decoration: _inputDecoration('Shipping Address', Icons.local_shipping_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Bar
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        foregroundColor: const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isSaving = true);
                              await widget.onSave({
                                'name': _nameCtrl.text.trim(),
                                'gstin': _gstinCtrl.text.trim(),
                                'phone': _phoneCtrl.text.trim(),
                                'email': _emailCtrl.text.trim(),
                                'state_code': _stateCode,
                                'address': _addressCtrl.text.trim(),
                                'shipping_address': _shippingCtrl.text.trim(),
                              });
                              if (mounted) setState(() => _isSaving = false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'AUTHORIZE UPDATE' : 'REGISTER ENTITY', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5, color: Color(0xFF94A3B8)),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE11D48))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      counterText: '',
    );
  }
}
