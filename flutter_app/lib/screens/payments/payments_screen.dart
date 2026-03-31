import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _api = ApiService();
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(AppConstants.payments);
      List items = [];
      if (data is Map && data['results'] != null) {
        items = data['results'];
      } else if (data is List) {
        items = data;
      }
      setState(() {
        _payments = items.map((p) => Payment.fromJson(p)).toList();
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

  void _showForm() {
    showDialog(
      context: context,
      builder: (ctx) => _PaymentDialog(
        api: _api,
        onSave: (data) async {
          await _api.post(AppConstants.payments, data: data);
          if (mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Payment recorded successfully'),
                  backgroundColor: Colors.green),
            );
            _load();
          }
        },
      ),
    );
  }

  Color _modeColor(String? mode) {
    switch (mode?.toUpperCase()) {
      case 'CASH':
        return Colors.green;
      case 'BANK':
      case 'BANK TRANSFER':
        return Colors.blue;
      case 'UPI':
        return Colors.purple;
      case 'CARD':
        return Colors.amber;
      case 'CHEQUE':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  IconData _modeIcon(String? mode) {
    switch (mode?.toUpperCase()) {
      case 'CASH':
        return Icons.money;
      case 'BANK':
      case 'BANK TRANSFER':
        return Icons.account_balance;
      case 'UPI':
        return Icons.qr_code;
      case 'CARD':
        return Icons.credit_card;
      case 'CHEQUE':
        return Icons.article;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##,###.##', 'en_IN');
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Payments',
      fab: FloatingActionButton.extended(
        onPressed: _showForm,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[200]),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_rounded, size: 80, color: Colors.grey[200]),
                          const SizedBox(height: 16),
                          const Text('No payments recorded yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const Text('Tap "Record Payment" to get started', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: _payments.length,
                        itemBuilder: (context, i) {
                          final p = _payments[i];
                          final modeColor = _modeColor(p.paymentMode);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: const Color(0xFFF1F5F9), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: modeColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(_modeIcon(p.paymentMode), color: modeColor, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.invoiceNumber ?? 'NO-INVOICE',
                                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              p.paymentMode?.toUpperCase() ?? '-',
                                              style: TextStyle(color: modeColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                            ),
                                            if ((p.paymentDate ?? '').isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                                              const SizedBox(width: 8),
                                              Text(
                                                p.paymentDate!,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if ((p.referenceNumber ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ref: ${p.referenceNumber}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${formatter.format(p.amount ?? 0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Color(0xFF059669),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      if ((p.notes ?? '').isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Has Notes',
                                            style: TextStyle(fontSize: 10, color: Colors.blueGrey[400], fontWeight: FontWeight.bold),
                                          ),
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
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final ApiService api;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _PaymentDialog({required this.api, required this.onSave});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Invoice? _selectedInvoice;
  List<Invoice> _invoices = [];
  String _paymentMode = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingInvoices = true;

  final List<String> _modes = ['CASH', 'BANK', 'UPI', 'CARD', 'CHEQUE'];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    try {
      final data = await widget.api.get(AppConstants.invoices);
      List items = [];
      if (data is Map && data['results'] != null) items = data['results'];
      else if (data is List) items = data;
      final all = items.map((i) => Invoice.fromJson(i)).toList();
      setState(() {
        _invoices = all.where((inv) =>
            inv.status?.toUpperCase() != 'PAID' &&
            inv.status?.toUpperCase() != 'CANCELLED').toList();
        _isLoadingInvoices = false;
      });
    } catch (_) {
      setState(() => _isLoadingInvoices = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
            dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  double _balanceDue(Invoice inv) {
    final total = inv.total ?? 0.0;
    final raw = inv.toJson()['amount_paid'];
    final paid = raw is num ? raw.toDouble() : 0.0;
    return total - paid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Record Payment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Acknowledge incoming business revenue', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Flexible(
              child: _isLoadingInvoices
                  ? Container(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary),
                            const SizedBox(height: 16),
                            const Text('FETCHING INVOICES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('SOURCE & AMOUNT'),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Invoice>(
                              isExpanded: true,
                              value: _selectedInvoice,
                              dropdownColor: Colors.white,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 14),
                              decoration: _inputDecoration('Select Linked Invoice', Icons.receipt_long_rounded),
                              items: _invoices.map((inv) {
                                final due = _balanceDue(inv);
                                return DropdownMenuItem(
                                  value: inv,
                                  child: Text(
                                    '${inv.invoiceNumber} • ₹${formatter.format(due)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedInvoice = v),
                              validator: (v) => v == null ? 'Please select an invoice' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 18),
                              decoration: _inputDecoration('Settlement Amount', Icons.currency_rupee_rounded).copyWith(
                                suffixText: 'INR',
                                suffixStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF94A3B8)),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter amount';
                                if (double.tryParse(v) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeader('METHOD & DATE'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _paymentMode,
                                    decoration: _inputDecoration('Mode', Icons.bolt_rounded),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                    items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                    onChanged: (v) => setState(() => _paymentMode = v!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDate,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InputDecorator(
                                      decoration: _inputDecoration('Date', Icons.calendar_month_rounded),
                                      child: Text(DateFormat('dd MMM yyyy').format(_paymentDate), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _referenceCtrl,
                              decoration: _inputDecoration('Reference Number (UTR/ID)', Icons.fingerprint_rounded),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeader('ADDITIONAL REMARKS'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesCtrl,
                              decoration: _inputDecoration('Notes', Icons.chat_bubble_outline_rounded).copyWith(hintText: 'Internal records only...'),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSaving = true);
                        try {
                          await widget.onSave({
                            'invoice': _selectedInvoice?.id,
                            'amount': double.tryParse(_amountCtrl.text) ?? 0,
                            'mode': _paymentMode,
                            'date': DateFormat('yyyy-MM-dd').format(_paymentDate),
                            'reference_number': _referenceCtrl.text,
                            'notes': _notesCtrl.text,
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFE11D48)));
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('AUTHORIZE PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5));
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
