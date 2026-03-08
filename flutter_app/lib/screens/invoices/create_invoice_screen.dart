import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class _ItemRow {
  Product? product;
  final TextEditingController hsnCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController priceCtrl = TextEditingController();
  double gstRate = 18.0;

  void dispose() {
    hsnCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get baseAmount => qty * price;
  double get gstAmount => baseAmount * gstRate / 100;
  double get total => baseAmount + gstAmount;
}

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _invoiceNumberCtrl = TextEditingController();
  String _invoiceType = InvoiceTypes.taxInvoice;
  String? _selectedDate;
  String? _selectedDueDate;
  Customer? _selectedCustomer;
  CompanySettings? _companySettings;

  List<Customer> _customers = [];
  List<Product> _products = [];
  List<_ItemRow> _items = [_ItemRow()];
  bool _isLoading = false;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateFormat('yyyy-MM-dd').format(now);
    _selectedDueDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30)));
    _loadData();
  }

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.get(AppConstants.customers),
        _api.get(AppConstants.products),
        _api.get(AppConstants.companySettings),
      ]);

      List customerList = [];
      if (results[0] is Map && results[0]['results'] != null) {
        customerList = results[0]['results'];
      } else if (results[0] is List) {
        customerList = results[0];
      }

      List productList = [];
      if (results[1] is Map && results[1]['results'] != null) {
        productList = results[1]['results'];
      } else if (results[1] is List) {
        productList = results[1];
      }

      setState(() {
        _customers = customerList.map((c) => Customer.fromJson(c)).toList();
        _products = productList.map((p) => Product.fromJson(p)).toList();
        if (results[2] is Map) {
          _companySettings = CompanySettings.fromJson(results[2]);
        } else if (results[2] is List && (results[2] as List).isNotEmpty) {
          _companySettings = CompanySettings.fromJson((results[2] as List).first);
        }
        _isDataLoading = false;
      });
    } catch (e) {
      setState(() => _isDataLoading = false);
    }
  }

  bool get _isInterState {
    if (_selectedCustomer == null || _companySettings == null) return false;
    return _selectedCustomer!.stateCode != _companySettings!.stateCode;
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.baseAmount);

  double get _totalGst => _items.fold(0, (sum, i) => sum + i.gstAmount);

  double get _cgst => _isInterState ? 0 : _totalGst / 2;
  double get _sgst => _isInterState ? 0 : _totalGst / 2;
  double get _igst => _isInterState ? _totalGst : 0;
  double get _total => _subtotal + _totalGst;

  Future<void> _selectDate(bool isDueDate) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isDueDate) {
          _selectedDueDate = formatted;
        } else {
          _selectedDate = formatted;
        }
      });
    }
  }

  Future<void> _saveInvoice(bool issue) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_items.every((i) => i.product == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final invoiceData = {
        'invoice_number': _invoiceNumberCtrl.text.trim(),
        'invoice_type': _invoiceType,
        'customer': _selectedCustomer!.id,
        'date': _selectedDate,
        'due_date': _selectedDueDate,
        'status': 'Draft',
      };

      final created = await _api.post(AppConstants.invoices, data: invoiceData);
      final invoiceId = created['id'];

      for (final item in _items) {
        if (item.product == null) continue;
        await _api.post(AppConstants.invoiceAddItem(invoiceId), data: {
          'product': item.product!.id,
          'hsn_sac': item.hsnCtrl.text,
          'quantity': item.qty,
          'unit_price': item.price,
          'gst_rate': item.gstRate,
        });
      }

      if (issue) {
        await _api.post(AppConstants.invoiceIssue(invoiceId));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(issue ? 'Invoice issued!' : 'Invoice saved as draft'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/invoices');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return AppScaffold(
      title: 'Create Invoice',
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invoice Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _invoiceType,
                              decoration: const InputDecoration(labelText: 'Invoice Type', border: OutlineInputBorder()),
                              items: InvoiceTypes.all.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _invoiceType = v!),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _invoiceNumberCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Invoice Number (leave blank for auto)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(false),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Invoice Date', border: OutlineInputBorder()),
                                      child: Text(_selectedDate ?? ''),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(true),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                                      child: Text(_selectedDueDate ?? ''),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Customer>(
                              value: _selectedCustomer,
                              decoration: const InputDecoration(labelText: 'Customer *', border: OutlineInputBorder()),
                              items: _customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? ''))).toList(),
                              onChanged: (v) => setState(() => _selectedCustomer = v),
                              validator: (v) => v == null ? 'Select customer' : null,
                            ),
                            if (_selectedCustomer != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isInterState ? Icons.swap_horiz : Icons.home,
                                      color: _isInterState ? Colors.orange : Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isInterState ? 'Inter-State: IGST will apply' : 'Intra-State: CGST + SGST will apply',
                                      style: TextStyle(
                                        color: _isInterState ? Colors.orange[700] : Colors.blue[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Line Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ElevatedButton.icon(
                                  onPressed: () => setState(() => _items.add(_ItemRow())),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Item'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Card(
                                color: Colors.grey[50],
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text('Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Spacer(),
                                          if (_items.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () => setState(() {
                                                _items[index].dispose();
                                                _items.removeAt(index);
                                              }),
                                            ),
                                        ],
                                      ),
                                      DropdownButtonFormField<Product>(
                                        value: item.product,
                                        decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
                                        items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name ?? ''))).toList(),
                                        onChanged: (p) {
                                          setState(() {
                                            item.product = p;
                                            if (p != null) {
                                              item.hsnCtrl.text = p.hsnSac ?? '';
                                              item.priceCtrl.text = p.price?.toString() ?? '';
                                              item.gstRate = p.gstRate ?? 18.0;
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: item.hsnCtrl,
                                              decoration: const InputDecoration(labelText: 'HSN/SAC', border: OutlineInputBorder()),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonFormField<double>(
                                              value: item.gstRate,
                                              decoration: const InputDecoration(labelText: 'GST %', border: OutlineInputBorder()),
                                              items: GstRates.rates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%'))).toList(),
                                              onChanged: (v) => setState(() => item.gstRate = v!),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: item.qtyCtrl,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              controller: item.priceCtrl,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(labelText: 'Unit Price', border: OutlineInputBorder()),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: InputDecorator(
                                              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                                              child: Text('₹${formatter.format(item.total)}'),
                                            ),
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
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _SummaryRow(label: 'Subtotal', value: '₹${formatter.format(_subtotal)}'),
                            if (!_isInterState) ...[
                              _SummaryRow(label: 'CGST', value: '₹${formatter.format(_cgst)}'),
                              _SummaryRow(label: 'SGST', value: '₹${formatter.format(_sgst)}'),
                            ] else ...[
                              _SummaryRow(label: 'IGST', value: '₹${formatter.format(_igst)}'),
                            ],
                            const Divider(),
                            _SummaryRow(
                              label: 'Total',
                              value: '₹${formatter.format(_total)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _saveInvoice(false),
                            child: const Text('Save as Draft'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _saveInvoice(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save & Issue'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null),
          Text(value, style: isBold ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null),
        ],
      ),
    );
  }
}
