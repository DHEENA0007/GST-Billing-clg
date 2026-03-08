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
      builder: (ctx) => AlertDialog(
        title: const Text('Issue Invoice'),
        content: Text(
            'Issue invoice ${inv.invoiceNumber}? This will send it to the customer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Issue'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.post(AppConstants.invoiceIssue(inv.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invoice issued successfully'),
              backgroundColor: Colors.green),
        );
      }
      _loadInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelInvoice(Invoice inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: Text(
            'Cancel invoice ${inv.invoiceNumber}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Invoice',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.post(AppConstants.invoiceCancel(inv.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invoice cancelled'),
              backgroundColor: Colors.orange),
        );
      }
      _loadInvoices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
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
                  fullInv.invoiceType?.toUpperCase() ?? 'TAX INVOICE',
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
    final formatter = NumberFormat('#,##,###.##', 'en_IN');

    return AppScaffold(
      title: 'Invoices',
      fab: FloatingActionButton.extended(
        onPressed: () => context.go('/invoices/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by invoice # or customer name...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadInvoices();
                            })
                        : null,
                  ),
                  onSubmitted: (_) => _loadInvoices(),
                  onChanged: (_) => _loadInvoices(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((status) {
                      final isSelected = _statusFilter == status;
                      Color chipColor = Colors.grey;
                      switch (status) {
                        case 'PAID':
                          chipColor = Colors.green;
                          break;
                        case 'ISSUED':
                          chipColor = Colors.blue;
                          break;
                        case 'PARTIAL':
                          chipColor = Colors.amber;
                          break;
                        case 'CANCELLED':
                          chipColor = Colors.red;
                          break;
                        case 'DRAFT':
                          chipColor = Colors.grey;
                          break;
                        default:
                          chipColor = Theme.of(context)
                              .colorScheme
                              .primary;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          selectedColor: chipColor.withOpacity(0.2),
                          checkmarkColor: chipColor,
                          labelStyle: TextStyle(
                              color: isSelected ? chipColor : null),
                          onSelected: (_) {
                            setState(() => _statusFilter = status);
                            _loadInvoices();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
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
                                onPressed: _loadInvoices,
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _invoices.isEmpty
                        ? const Center(
                            child: Text('No invoices found'))
                        : RefreshIndicator(
                            onRefresh: _loadInvoices,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  12, 8, 12, 80),
                              itemCount: _invoices.length + 1,
                              itemBuilder: (context, index) {
                                if (index == _invoices.length) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'Showing ${_invoices.length} invoice${_invoices.length == 1 ? '' : 's'}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12),
                                    ),
                                  );
                                }
                                final inv = _invoices[index];
                                final statusColor =
                                    _statusColor(inv.status);
                                return Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.receipt,
                                                size: 18,
                                                color: Colors.indigo),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                inv.invoiceNumber ?? '-',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                              ),
                                              child: Text(
                                                inv.status ?? '',
                                                style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.person_outline,
                                                size: 13,
                                                color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                inv.customerName ?? '-',
                                                style: TextStyle(
                                                    color:
                                                        Colors.grey[700],
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .calendar_today_outlined,
                                                size: 13,
                                                color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Date: ${inv.date ?? '-'}',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  '₹${formatter.format(inv.total ?? 0)}',
                                                  style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.indigo),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                // PDF download
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .picture_as_pdf_outlined,
                                                      color: Colors.orange),
                                                  tooltip:
                                                      'Download PDF',
                                                  onPressed: () =>
                                                      _downloadPdf(inv),
                                                ),
                                                // Issue (only DRAFT)
                                                if (inv.status
                                                        ?.toUpperCase() ==
                                                    'DRAFT')
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.send,
                                                        color: Colors.blue),
                                                    tooltip: 'Issue',
                                                    onPressed: () =>
                                                        _issueInvoice(inv),
                                                  ),
                                                // Cancel (DRAFT or ISSUED)
                                                if (inv.status
                                                            ?.toUpperCase() ==
                                                        'DRAFT' ||
                                                    inv.status
                                                            ?.toUpperCase() ==
                                                        'ISSUED')
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons
                                                            .cancel_outlined,
                                                        color: Colors.red),
                                                    tooltip: 'Cancel',
                                                    onPressed: () =>
                                                        _cancelInvoice(inv),
                                                  ),
                                              ],
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
