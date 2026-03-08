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

    return AppScaffold(
      title: 'Payments',
      fab: FloatingActionButton.extended(
        onPressed: _showForm,
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
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
              : _payments.isEmpty
                  ? const Center(child: Text('No payments found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 12, 16, 80),
                        itemCount: _payments.length,
                        itemBuilder: (context, i) {
                          final p = _payments[i];
                          final modeColor = _modeColor(p.paymentMode);

                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: modeColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                        _modeIcon(p.paymentMode),
                                        color: modeColor,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Invoice: ${p.invoiceNumber ?? '-'}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            Text(
                                              '₹${formatter.format(p.amount ?? 0)}',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.green),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: modeColor
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                              ),
                                              child: Text(
                                                p.paymentMode
                                                        ?.toUpperCase() ??
                                                    '-',
                                                style: TextStyle(
                                                    color: modeColor,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if ((p.paymentDate ?? '').isNotEmpty)
                                              Text(
                                                p.paymentDate!,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.grey[600]),
                                              ),
                                          ],
                                        ),
                                        if ((p.referenceNumber ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Ref: ${p.referenceNumber}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                        if ((p.notes ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            p.notes!,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
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

  final List<String> _modes = [
    'CASH',
    'BANK',
    'UPI',
    'CARD',
    'CHEQUE',
  ];

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
      if (data is Map && data['results'] != null) {
        items = data['results'];
      } else if (data is List) {
        items = data;
      }
      final all = items.map((i) => Invoice.fromJson(i)).toList();
      setState(() {
        _invoices = all
            .where((inv) =>
                inv.status?.toUpperCase() != 'PAID' &&
                inv.status?.toUpperCase() != 'CANCELLED')
            .toList();
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
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  double _balanceDue(Invoice inv) {
    final total = inv.total ?? 0.0;
    final raw = inv.toJson()['amount_paid'];
    final paid = raw is num ? raw.toDouble() : 0.0;
    return total - paid;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: SizedBox(
        width: 500,
        child: _isLoadingInvoices
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Invoice dropdown
                      DropdownButtonFormField<Invoice>(
                        value: _selectedInvoice,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Invoice *',
                            border: OutlineInputBorder()),
                        items: _invoices.map((inv) {
                          final due = _balanceDue(inv);
                          return DropdownMenuItem(
                            value: inv,
                            child: Text(
                              '${inv.invoiceNumber} | ${inv.customerName ?? ''} | Due: ₹${NumberFormat('#,##,###.##', 'en_IN').format(due)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedInvoice = v),
                        validator: (v) =>
                            v == null ? 'Select an invoice' : null,
                      ),
                      const SizedBox(height: 12),
                      // Amount
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Amount *',
                            border: OutlineInputBorder(),
                            prefixText: '₹ '),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Payment Mode
                      DropdownButtonFormField<String>(
                        value: _paymentMode,
                        decoration: const InputDecoration(
                            labelText: 'Payment Mode *',
                            border: OutlineInputBorder()),
                        items: _modes
                            .map((m) => DropdownMenuItem(
                                value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _paymentMode = v!),
                      ),
                      const SizedBox(height: 12),
                      // Date picker
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Payment Date *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(
                                  Icons.calendar_today)),
                          child: Text(DateFormat('dd/MM/yyyy')
                              .format(_paymentDate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Reference No
                      TextFormField(
                        controller: _referenceCtrl,
                        decoration: const InputDecoration(
                            labelText:
                                'Reference No. (UTR/Cheque No)',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder()),
                        maxLines: 2,
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
                      'invoice': _selectedInvoice?.id,
                      'amount': double.tryParse(_amountCtrl.text) ?? 0,
                      'payment_mode': _paymentMode,
                      'payment_date': DateFormat('yyyy-MM-dd')
                          .format(_paymentDate),
                      'reference_number': _referenceCtrl.text,
                      'notes': _notesCtrl.text,
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2))
              : const Text('Record Payment'),
        ),
      ],
    );
  }
}
