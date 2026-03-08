import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Vendor> _vendors = [];
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
      final params = <String, dynamic>{};
      if (_searchCtrl.text.isNotEmpty) params['search'] = _searchCtrl.text;
      final data = await _api.get(AppConstants.vendors, queryParameters: params);
      List items = [];
      if (data is Map && data['results'] != null) items = data['results'];
      else if (data is List) items = data;
      setState(() {
        _vendors = items.map((v) => Vendor.fromJson(v)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _delete(Vendor v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Delete ${v.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('${AppConstants.vendors}${v.id}/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor deleted'), backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _showForm({Vendor? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _VendorForm(
        vendor: existing,
        onSave: (data) async {
          try {
            if (existing != null) {
              await _api.put('${AppConstants.vendors}${existing.id}/', data: data);
            } else {
              await _api.post(AppConstants.vendors, data: data);
            }
            if (mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(existing != null ? 'Vendor updated' : 'Vendor added'),
                backgroundColor: Colors.green,
              ));
              _load();
            }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Vendors',
      fab: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Vendor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
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
                    : _vendors.isEmpty
                        ? const Center(child: Text('No vendors found'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              itemCount: _vendors.length,
                              itemBuilder: (context, i) {
                                final v = _vendors[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.teal.withOpacity(0.1),
                                      child: Text(
                                        (v.name ?? 'V')[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(v.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (v.phone != null) Text(v.phone!),
                                        if (v.email != null && v.email!.isNotEmpty) Text(v.email!, style: const TextStyle(fontSize: 12)),
                                        if (v.gstin != null && v.gstin!.isNotEmpty)
                                          Text('GSTIN: ${v.gstin}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        if (v.address != null)
                                          Text(v.address!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                          onPressed: () => _showForm(existing: v),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _delete(v),
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

class _VendorForm extends StatefulWidget {
  final Vendor? vendor;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _VendorForm({this.vendor, required this.onSave});

  @override
  State<_VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends State<_VendorForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _gstinCtrl;
  String? _stateCode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vendor;
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _emailCtrl = TextEditingController(text: v?.email ?? '');
    _phoneCtrl = TextEditingController(text: v?.phone ?? '');
    _addressCtrl = TextEditingController(text: v?.address ?? '');
    _gstinCtrl = TextEditingController(text: v?.gstin ?? '');
    _stateCode = v?.stateCode;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.vendor != null ? 'Edit Vendor' : 'Add Vendor'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Vendor Name *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gstinCtrl,
                  decoration: const InputDecoration(labelText: 'GSTIN', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (v.length != 15) return 'GSTIN must be 15 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _stateCode,
                  decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                  items: IndianStates.states.map((s) => DropdownMenuItem(
                    value: s['code'],
                    child: Text('${s['code']} - ${s['name']}'),
                  )).toList(),
                  onChanged: (v) => setState(() => _stateCode = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _isSaving = true);
            await widget.onSave({
              'name': _nameCtrl.text,
              'email': _emailCtrl.text,
              'phone': _phoneCtrl.text,
              'address': _addressCtrl.text,
              'gstin': _gstinCtrl.text,
              'state_code': _stateCode,
            });
            if (mounted) setState(() => _isSaving = false);
          },
          child: _isSaving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
