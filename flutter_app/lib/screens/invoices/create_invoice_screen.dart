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
        'status': 'DRAFT',
      };

      final created = await _api.post(AppConstants.invoices, data: invoiceData);
      final invoiceId = created['id'];

      for (final item in _items) {
        if (item.product == null) continue;
        await _api.post(AppConstants.invoiceAddItem(invoiceId), data: {
          'product': item.product!.id,
          'description': item.hsnCtrl.text,
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
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return AppScaffold(
      title: 'Create Invoice',
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('CORE PARAMETERS', Icons.tune_rounded),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _invoiceType,
                              dropdownColor: Colors.white,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 14),
                              decoration: _inputDecoration('Invoice Classification', Icons.receipt_long_rounded),
                              items: InvoiceTypes.all.map((t) => DropdownMenuItem(value: t, child: Text(InvoiceTypes.labels[t] ?? t))).toList(),
                              onChanged: (v) => setState(() => _invoiceType = v!),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _invoiceNumberCtrl,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                              decoration: _inputDecoration('Record Number', Icons.tag_rounded).copyWith(
                                hintText: 'SYSTEM AUTO-GENERATE',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(false),
                                    borderRadius: BorderRadius.circular(16),
                                    child: InputDecorator(
                                      decoration: _inputDecoration('Issued On', Icons.calendar_today_rounded),
                                      child: Text(_selectedDate ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(true),
                                    borderRadius: BorderRadius.circular(16),
                                    child: InputDecorator(
                                      decoration: _inputDecoration('Payment Due', Icons.event_available_rounded),
                                      child: Text(_selectedDueDate ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Customer>(
                              value: _selectedCustomer,
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 14),
                              decoration: _inputDecoration('Client / Business Associate', Icons.person_rounded),
                              items: _customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? ''))).toList(),
                              onChanged: (v) => setState(() => _selectedCustomer = v),
                              validator: (v) => v == null ? 'Selection required' : null,
                            ),
                            if (_selectedCustomer != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isInterState ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _isInterState ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isInterState ? Icons.public_rounded : Icons.location_on_rounded,
                                      color: _isInterState ? const Color(0xFFC2410C) : const Color(0xFF166534),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _isInterState ? 'INTER-STATE GST APPLIED (IGST)' : 'INTRA-STATE GST APPLIED (CGST + SGST)',
                                        style: TextStyle(
                                          color: _isInterState ? const Color(0xFF9A3412) : const Color(0xFF15803D),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
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
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('BILLING LINE ITEMS', Icons.list_alt_rounded),
                        TextButton.icon(
                          onPressed: () => setState(() => _items.add(_ItemRow())),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          label: const Text('ADD LINE ITEM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Text('ITEM #${index + 1}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                                    ),
                                    const Spacer(),
                                    if (_items.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                                        onPressed: () => setState(() {
                                          _items[index].dispose();
                                          _items.removeAt(index);
                                        }),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<Product>(
                                  value: item.product,
                                  dropdownColor: Colors.white,
                                  isExpanded: true,
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13),
                                  decoration: _inputDecoration('Search / Link Product', Icons.inventory_2_rounded),
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
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: item.hsnCtrl,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                        decoration: _inputDecoration('HSN/SAC', Icons.api_rounded),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<double>(
                                        isExpanded: true,
                                        value: item.gstRate,
                                        dropdownColor: Colors.white,
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                                        decoration: _inputDecoration('GST %', Icons.percent_rounded),
                                        items: GstRates.rates.map((r) => DropdownMenuItem(value: r, child: Text('${r.toInt()}%'))).toList(),
                                        onChanged: (v) => setState(() => item.gstRate = v!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: item.qtyCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                        decoration: _inputDecoration('Qty', Icons.shutter_speed_rounded),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: item.priceCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                        decoration: _inputDecoration('Unit Rate', Icons.payments_rounded),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('NET PAYABLE (THIS LINE)', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 0.5)),
                                      Text('₹${formatter.format(item.total)}', style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 16, letterSpacing: -0.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildSectionTitle('FINANCIAL LEDGER', Icons.account_balance_wallet_rounded),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            _SummaryRow(label: 'Total Assessable Value', value: '₹${formatter.format(_subtotal)}'),
                            const SizedBox(height: 12),
                            if (!_isInterState) ...[
                              _SummaryRow(label: 'Central Tax (CGST)', value: '₹${formatter.format(_cgst)}'),
                              const SizedBox(height: 8),
                              _SummaryRow(label: 'State Tax (SGST)', value: '₹${formatter.format(_sgst)}'),
                            ] else ...[
                              _SummaryRow(label: 'Integrated Tax (IGST)', value: '₹${formatter.format(_igst)}'),
                            ],
                            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFE2E8F0))),
                            _SummaryRow(
                              label: 'Total Document Value',
                              value: '₹${formatter.format(_total)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _saveInvoice(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: BorderSide(color: theme.colorScheme.primary, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('SAVE DRAFT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _saveInvoice(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('FINALIZE & ISSUE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.5,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE11D48))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            fontSize: isBold ? 18 : 14,
            color: isBold ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            fontSize: isBold ? 18 : 14,
            color: isBold ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
