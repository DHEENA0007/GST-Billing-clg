import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Product> _products = [];
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
      final data = await _api.get(AppConstants.products, queryParameters: params);
      List items = [];
      if (data is Map && data['results'] != null) items = data['results'];
      else if (data is List) items = data;
      setState(() {
        _products = items.map((p) => Product.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _delete(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete ${p.name}?'),
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
      await _api.delete('${AppConstants.products}${p.id}/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted'), backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _showForm({Product? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductForm(
        product: existing,
        onSave: (data) async {
          try {
            if (existing != null) {
              await _api.put('${AppConstants.products}${existing.id}/', data: data);
            } else {
              await _api.post(AppConstants.products, data: data);
            }
            if (mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(existing != null ? 'Product updated' : 'Product added'),
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
    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return AppScaffold(
      title: 'Products',
      fab: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products...',
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
                    : _products.isEmpty
                        ? const Center(child: Text('No products found'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              itemCount: _products.length,
                              itemBuilder: (context, i) {
                                final p = _products[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.inventory_2_outlined, color: Colors.indigo),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(p.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 8),
                                                  if (p.isLowStock)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red[50],
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: Colors.red),
                                                      ),
                                                      child: Text('Low Stock', style: TextStyle(fontSize: 10, color: Colors.red[700])),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'HSN: ${p.hsnSac ?? '-'}  |  GST: ${p.gstRate?.toInt() ?? 0}%  |  Unit: ${p.unit ?? '-'}',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹${formatter.format(p.price ?? 0)}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    'Stock: ${p.stock ?? 0}',
                                                    style: TextStyle(
                                                      color: p.isLowStock ? Colors.red : Colors.grey[600],
                                                      fontWeight: p.isLowStock ? FontWeight.bold : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                              onPressed: () => _showForm(existing: p),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              onPressed: () => _delete(p),
                                            ),
                                          ],
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

class _ProductForm extends StatefulWidget {
  final Product? product;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _ProductForm({this.product, required this.onSave});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _hsnCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _thresholdCtrl;
  double _gstRate = 18.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _hsnCtrl = TextEditingController(text: p?.hsnSac ?? '');
    _priceCtrl = TextEditingController(text: p?.price?.toString() ?? '');
    _unitCtrl = TextEditingController(text: p?.unit ?? '');
    _stockCtrl = TextEditingController(text: p?.stock?.toString() ?? '0');
    _thresholdCtrl = TextEditingController(text: p?.lowStockThreshold?.toString() ?? '5');
    _gstRate = p?.gstRate ?? 18.0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _hsnCtrl.dispose();
    _priceCtrl.dispose();
    _unitCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
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
                  decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hsnCtrl,
                        decoration: const InputDecoration(labelText: 'HSN/SAC Code', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: _gstRate,
                        decoration: const InputDecoration(labelText: 'GST Rate', border: OutlineInputBorder()),
                        items: GstRates.rates.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('${r.toInt()}%'),
                        )).toList(),
                        onChanged: (v) => setState(() => _gstRate = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Unit Price *', border: OutlineInputBorder(), prefixText: '₹'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unit (e.g., Pcs, Kg)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _thresholdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Low Stock Threshold', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);
                  await widget.onSave({
                    'name': _nameCtrl.text,
                    'description': _descCtrl.text,
                    'hsn_sac': _hsnCtrl.text,
                    'price': double.tryParse(_priceCtrl.text) ?? 0,
                    'gst_rate': _gstRate,
                    'unit': _unitCtrl.text,
                    'stock': int.tryParse(_stockCtrl.text) ?? 0,
                    'low_stock_threshold': int.tryParse(_thresholdCtrl.text) ?? 5,
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
