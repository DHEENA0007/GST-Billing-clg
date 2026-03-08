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
    final filtered = _filtered;
    final isWide = MediaQuery.of(context).size.width > 600;

    return AppScaffold(
      title: 'Customers',
      fab: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customers...',
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text('No customers found'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final innerWidth = constraints.maxWidth - 32;
                                final crossCount = isWide ? 2 : 1;
                                final itemWidth = (innerWidth - ((crossCount - 1) * 12)) / crossCount;
                                final aspect = itemWidth / 150.0;

                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossCount,
                                    childAspectRatio: aspect,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {
                                    final c = filtered[i];
                                    return _CustomerCard(
                                      customer: c,
                                      stateLabel: _stateLabel(c.stateCode),
                                      onEdit: () => _showForm(existing: c),
                                      onDelete: () => _delete(c),
                                    );
                                  },
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Colors.indigo.withOpacity(0.1),
                  child: Text(
                    (customer.name ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      if ((customer.gstin ?? '').isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: Colors.green),
                          ),
                          child: Text(customer.gstin!,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[800])),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if ((customer.phone ?? '').isNotEmpty)
              _InfoRow(icon: Icons.phone, text: customer.phone!),
            if ((customer.email ?? '').isNotEmpty)
              _InfoRow(icon: Icons.email, text: customer.email!),
            if (stateLabel.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(stateLabel,
                        style: TextStyle(
                            fontSize: 10, color: Colors.blue[800])),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CustomerDialog extends StatefulWidget {
  final ApiService api;
  final Customer? customer;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _CustomerDialog(
      {required this.api, this.customer, required this.onSave});

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
    _shippingCtrl =
        TextEditingController(text: c?.shippingAddress ?? '');
    _stateCode = c?.stateCode ?? '29';
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
      final result = await widget.api.post(
          '${AppConstants.customers}validate_gstin/',
          data: {'gstin': gstin});
      setState(() {
        _gstinValidationMsg =
            result is Map && result['valid'] == true
                ? 'Valid GSTIN'
                : 'Invalid GSTIN';
        _gstinValidating = false;
      });
    } catch (_) {
      setState(() {
        _gstinValidationMsg = 'Validation failed';
        _gstinValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer != null
          ? 'Edit Customer'
          : 'Add Customer'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gstinCtrl,
                        decoration: const InputDecoration(
                            labelText: 'GSTIN',
                            border: OutlineInputBorder()),
                        maxLength: 15,
                        onChanged: (_) =>
                            setState(() => _gstinValidationMsg = null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _gstinValidating
                          ? null
                          : _validateGstin,
                      child: _gstinValidating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Text('Validate'),
                    ),
                  ],
                ),
                if (_gstinValidationMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _gstinValidationMsg!,
                      style: TextStyle(
                          color: _gstinValidationMsg == 'Valid GSTIN'
                              ? Colors.green
                              : Colors.red,
                          fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Phone *',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Required'
                      : null,
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
                DropdownButtonFormField<String>(
                  value: _stateCode,
                  decoration: const InputDecoration(
                      labelText: 'State Code *',
                      border: OutlineInputBorder()),
                  isExpanded: true,
                  items: IndianStates.states
                      .map((s) => DropdownMenuItem(
                            value: s['code'],
                            child: Text(
                                '${s['code']} - ${s['name']}'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _stateCode = v),
                  validator: (v) =>
                      v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Billing Address *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shippingCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Shipping Address',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true),
                  maxLines: 3,
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
                  await widget.onSave({
                    'name': _nameCtrl.text,
                    'gstin': _gstinCtrl.text,
                    'phone': _phoneCtrl.text,
                    'email': _emailCtrl.text,
                    'state_code': _stateCode,
                    'address': _addressCtrl.text,
                    'shipping_address': _shippingCtrl.text,
                  });
                  if (mounted) setState(() => _isSaving = false);
                },
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.customer != null ? 'Update' : 'Add Customer'),
        ),
      ],
    );
  }
}
