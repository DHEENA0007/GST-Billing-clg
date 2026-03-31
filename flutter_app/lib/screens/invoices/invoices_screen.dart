import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'ALL';

  final List<String> _statusOptions = [
    'ALL',
    'DRAFT',
    'ISSUED',
    'PARTIAL',
    'PAID',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_statusFilter != 'ALL') params['status'] = _statusFilter;

      final data =
          await _api.get(AppConstants.invoices, queryParameters: params);
      List items = [];
      if (data is Map && data['results'] != null) {
        items = data['results'];
      } else if (data is List) {
        items = data;
      }

      List<Invoice> all =
          items.map((i) => Invoice.fromJson(i)).toList();

      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        all = all
            .where((inv) =>
                (inv.invoiceNumber?.toLowerCase().contains(q) ?? false) ||
                (inv.customerName?.toLowerCase().contains(q) ?? false))
            .toList();
      }

      setState(() {
        _invoices = all;
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

  Future<void> _issueInvoice(Invoice inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'EXECUTE ISSUANCE',
        content: 'Authorize the issuance of ${inv.invoiceNumber}? This will commit the document to the customer ledger.',
        confirmLabel: 'AUTHORIZE',
        icon: Icons.send_rounded,
        color: const Color(0xFF6366F1),
      ),
    );
    if (confirm != true) return;
    try {
      await _api.post(AppConstants.invoiceIssue(inv.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice issued successfully'), backgroundColor: Colors.green));
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _cancelInvoice(Invoice inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'CANCEL TRANSACTION',
        content: 'Are you sure you want to void ${inv.invoiceNumber}? This action is permanent and will revert all ledger entries.',
        confirmLabel: 'VOID INVOICE',
        icon: Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
      ),
    );
    if (confirm != true) return;
    try {
      await _api.post(AppConstants.invoiceCancel(inv.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice cancelled'), backgroundColor: Colors.orange));
        _loadInvoices();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _recordPayment(Invoice inv) async {
    await showDialog(
      context: context,
      builder: (ctx) => _RecordPaymentDialog(
        api: _api,
        invoice: inv,
        onSaved: () {
          _loadInvoices();
        },
      ),
    );
  }

  Future<void> _downloadPdf(Invoice inv) async {
    // Fetch full invoice detail for items
    Invoice fullInv = inv;
    try {
      final detail = await _api.get('${AppConstants.invoices}${inv.id}/');
      if (detail is Map) {
        fullInv = Invoice.fromJson(Map<String, dynamic>.from(detail));
      }
    } catch (_) {}

    final pdf = pw.Document();
    final fmt = NumberFormat('#,##,###.##', 'en_IN');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context ctx) => [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  InvoiceTypes.labels[fullInv.invoiceType?.toUpperCase()] ?? fullInv.invoiceType?.toUpperCase() ?? 'TAX INVOICE',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Invoice #: ${fullInv.invoiceNumber ?? '-'}'),
                pw.Text('Date: ${fullInv.date ?? '-'}'),
                if ((fullInv.dueDate ?? '').isNotEmpty)
                  pw.Text('Due Date: ${fullInv.dueDate}'),
              ],
            ),
          ],
        ),
        pw.Divider(height: 24),
        // Bill To
        pw.Text('BILL TO',
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(fullInv.customerName ?? '-',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 16),
        // Items table
        if ((fullInv.items ?? []).isNotEmpty) ...[
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  'Product',
                  'HSN',
                  'Qty',
                  'Rate',
                  'GST%',
                  'Total'
                ].map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(h,
                          style:
                              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    )).toList(),
              ),
              ...?fullInv.items?.map((item) => pw.TableRow(
                    children: [
                      item.productName ?? '-',
                      item.description ?? '-',
                      (item.quantity ?? 0).toString(),
                      '₹${fmt.format(item.unitPrice ?? 0)}',
                      '${item.gstRate ?? 0}%',
                      '₹${fmt.format(item.total ?? 0)}',
                    ].map((t) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(t.toString(), style: const pw.TextStyle(fontSize: 9)),
                        )).toList(),
                  )),
            ],
          ),
          pw.SizedBox(height: 16),
        ],
        // Summary
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.SizedBox(
              width: 200,
              child: pw.Column(
                children: [
                  _pdfRow('Subtotal', '₹${fmt.format(fullInv.subtotal ?? 0)}'),
                  if ((fullInv.cgstTotal ?? 0) > 0)
                    _pdfRow('CGST', '₹${fmt.format(fullInv.cgstTotal ?? 0)}'),
                  if ((fullInv.sgstTotal ?? 0) > 0)
                    _pdfRow('SGST', '₹${fmt.format(fullInv.sgstTotal ?? 0)}'),
                  if ((fullInv.igstTotal ?? 0) > 0)
                    _pdfRow('IGST', '₹${fmt.format(fullInv.igstTotal ?? 0)}'),
                  pw.Divider(),
                  _pdfRow('Grand Total', '₹${fmt.format(fullInv.total ?? 0)}',
                      bold: true),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text('Thank you for your business!',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'ISSUED':
        return Colors.blue;
      case 'PARTIAL':
        return Colors.amber;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return AppScaffold(
      title: 'Invoices',
      fab: FloatingActionButton.extended(
        onPressed: () => context.go('/invoices/create'),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('NEW INVOICE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
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
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadInvoices(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Search by Number or Customer...',
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
                              _loadInvoices();
                            })
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: _statusOptions.map((status) {
                      final isSelected = _statusFilter == status;
                      Color baseColor = Colors.white;
                      if (isSelected) {
                        switch (status) {
                          case 'PAID': baseColor = const Color(0xFF10B981); break;
                          case 'ISSUED': baseColor = const Color(0xFF6366F1); break;
                          case 'PARTIAL': baseColor = const Color(0xFFF59E0B); break;
                          case 'CANCELLED': baseColor = const Color(0xFFEF4444); break;
                          default: baseColor = Colors.white;
                        }
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _statusFilter = status);
                            _loadInvoices();
                          },
                          backgroundColor: Colors.white.withOpacity(0.1),
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _invoices.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadInvoices,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                                itemCount: _invoices.length,
                                itemBuilder: (context, index) {
                                  final inv = _invoices[index];
                                  return _InvoiceCard(
                                    invoice: inv,
                                    formatter: formatter,
                                    onPdf: () => _downloadPdf(inv),
                                    onIssue: inv.status?.toUpperCase() == 'DRAFT' ? () => _issueInvoice(inv) : null,
                                    onCancel: (inv.status?.toUpperCase() == 'DRAFT' || inv.status?.toUpperCase() == 'ISSUED') ? () => _cancelInvoice(inv) : null,
                                    onRecord: (inv.status?.toUpperCase() == 'ISSUED' || inv.status?.toUpperCase() == 'PARTIAL') ? () => _recordPayment(inv) : null,
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
            child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[400]),
          ),
          const SizedBox(height: 16),
          Text(_error ?? 'Sync error', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadInvoices, child: const Text('RETRY')),
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
            child: const Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          const Text('No Invoices Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const Text('Create your first sales record with "NEW INVOICE".', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat formatter;
  final VoidCallback onPdf;
  final VoidCallback? onIssue;
  final VoidCallback? onCancel;
  final VoidCallback? onRecord;

  const _InvoiceCard({required this.invoice, required this.formatter, required this.onPdf, this.onIssue, this.onCancel, this.onRecord});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColorForCard(invoice.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber ?? 'NO-INV',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B), letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.customerName?.toUpperCase() ?? 'ENTITY UNKNOWN',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            invoice.status?.toUpperCase() ?? 'DRAFT',
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LEDGER TOTAL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          '₹ ${formatter.format(invoice.total ?? 0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(invoice.date ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        if ((invoice.dueDate ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('DUE: ${invoice.dueDate}', style: const TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InvoiceAction(icon: Icons.description_rounded, label: 'INVOICE', color: const Color(0xFFF59E0B), onTap: onPdf),
                if (onIssue != null)
                  _InvoiceAction(icon: Icons.rocket_launch_rounded, label: 'ISSUE', color: const Color(0xFF6366F1), onTap: onIssue!),
                if (onRecord != null)
                  _InvoiceAction(icon: Icons.account_balance_wallet_rounded, label: 'RECORD', color: const Color(0xFF10B981), onTap: onRecord!),
                if (onCancel != null)
                  _InvoiceAction(icon: Icons.block_rounded, label: 'VOID', color: const Color(0xFFEF4444), onTap: onCancel!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColorForCard(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID': return const Color(0xFF10B981);
      case 'ISSUED': return const Color(0xFF6366F1);
      case 'PARTIAL': return const Color(0xFFF59E0B);
      case 'CANCELLED': return const Color(0xFFEF4444);
      default: return const Color(0xFF94A3B8);
    }
  }
}

class _InvoiceAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InvoiceAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordPaymentDialog extends StatefulWidget {
  final ApiService api;
  final Invoice invoice;
  final VoidCallback onSaved;

  const _RecordPaymentDialog({required this.api, required this.invoice, required this.onSaved});

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMode = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _modes = ['CASH', 'BANK', 'UPI', 'CARD', 'CHEQUE'];

  @override
  void initState() {
    super.initState();
    final balance = (widget.invoice.total ?? 0) - (widget.invoice.amountPaid ?? 0);
    _amountCtrl.text = balance > 0 ? balance.toStringAsFixed(2) : '';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##,###.##', 'en_IN');
    final balance = (widget.invoice.total ?? 0) - (widget.invoice.amountPaid ?? 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RECORD PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(widget.invoice.invoiceNumber ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Balance: ₹${fmt.format(balance)}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20, color: Color(0xFF64748B)),
                        suffixText: 'INR',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE11D48))),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE11D48), width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter amount';
                        if (double.tryParse(v) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentMode,
                            decoration: InputDecoration(
                              labelText: 'Mode',
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                            onChanged: (v) => setState(() => _paymentMode = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(16),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                prefixIcon: const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF64748B)),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              child: Text(DateFormat('dd MMM yyyy').format(_paymentDate), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenceCtrl,
                      decoration: InputDecoration(
                        labelText: 'Reference / UTR',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
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
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w900)),
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
                          await widget.api.post(AppConstants.payments, data: {
                            'invoice': widget.invoice.id,
                            'amount': double.tryParse(_amountCtrl.text) ?? 0,
                            'mode': _paymentMode,
                            'date': DateFormat('yyyy-MM-dd').format(_paymentDate),
                            'reference_number': _referenceCtrl.text,
                            'notes': _notesCtrl.text,
                          });
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment recorded successfully'), backgroundColor: Colors.green),
                            );
                            widget.onSaved();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('RECORD PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final IconData icon;
  final Color color;

  const _ConfirmDialog({required this.title, required this.content, required this.confirmLabel, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(content, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, height: 1.5)),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('DISMISS', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
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
}
