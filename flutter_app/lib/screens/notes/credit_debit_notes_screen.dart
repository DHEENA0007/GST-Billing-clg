import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class CreditDebitNotesScreen extends StatefulWidget {
  const CreditDebitNotesScreen({super.key});

  @override
  State<CreditDebitNotesScreen> createState() => _CreditDebitNotesScreenState();
}

class _CreditDebitNotesScreenState extends State<CreditDebitNotesScreen> {
  final _api = ApiService();
  List<CreditDebitNote> _notes = [];
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
      final data = await _api.get(AppConstants.creditDebitNotes);
      List items = [];
      if (data is Map && data['results'] != null) items = data['results'];
      else if (data is List) items = data;
      setState(() {
        _notes = items.map((n) => CreditDebitNote.fromJson(n)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _delete(CreditDebitNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete ${note.noteNumber}?'),
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
      await _api.delete('${AppConstants.creditDebitNotes}${note.id}/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted'), backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  void _showForm({CreditDebitNote? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _NoteForm(
        api: _api,
        note: existing,
        onSave: (data) async {
          try {
            if (existing != null) {
              await _api.put('${AppConstants.creditDebitNotes}${existing.id}/', data: data);
            } else {
              await _api.post(AppConstants.creditDebitNotes, data: data);
            }
            if (mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(existing != null ? 'Note updated' : 'Note created'),
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
      title: 'Credit/Debit Notes',
      fab: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_error!),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _notes.isEmpty
                  ? const Center(child: Text('No credit/debit notes'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _notes.length,
                        itemBuilder: (context, i) {
                          final n = _notes[i];
                          final isCredit = n.noteType?.toLowerCase() == 'credit';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isCredit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(n.noteNumber ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isCredit ? Colors.green : Colors.red).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                n.noteType ?? '',
                                                style: TextStyle(
                                                  color: isCredit ? Colors.green : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (n.invoiceNumber != null)
                                          Text('Invoice: ${n.invoiceNumber}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        if (n.date != null) Text('Date: ${n.date}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        if (n.reason != null) Text(n.reason!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${formatter.format(n.amount ?? 0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isCredit ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                            onPressed: () => _showForm(existing: n),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            onPressed: () => _delete(n),
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
    );
  }
}

class _NoteForm extends StatefulWidget {
  final ApiService api;
  final CreditDebitNote? note;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _NoteForm({required this.api, this.note, required this.onSave});

  @override
  State<_NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<_NoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _gstCtrl = TextEditingController(text: '0');
  String _noteType = NoteTypes.credit;
  String? _selectedDate;
  Invoice? _selectedInvoice;
  List<Invoice> _invoices = [];
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _reasonCtrl.text = n?.reason ?? '';
    _amountCtrl.text = n?.amount?.toString() ?? '';
    _gstCtrl.text = n?.gstAdjustment?.toString() ?? '0';
    _noteType = n?.noteType ?? NoteTypes.credit;
    _selectedDate = n?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadInvoices();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _amountCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    try {
      final data = await widget.api.get(AppConstants.invoices);
      List items = [];
      if (data is Map && data['results'] != null) items = data['results'];
      else if (data is List) items = data;
      setState(() {
        _invoices = items.map((i) => Invoice.fromJson(i)).toList();
        if (widget.note?.invoiceId != null) {
          _selectedInvoice = _invoices.firstWhere(
            (inv) => inv.id == widget.note!.invoiceId,
            orElse: () => _invoices.first,
          );
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note != null ? 'Edit Note' : 'Create Note'),
      content: SizedBox(
        width: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _noteType,
                        decoration: const InputDecoration(labelText: 'Note Type', border: OutlineInputBorder()),
                        items: NoteTypes.all.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _noteType = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Invoice>(
                        value: _selectedInvoice,
                        decoration: const InputDecoration(labelText: 'Linked Invoice', border: OutlineInputBorder()),
                        items: _invoices.map((inv) => DropdownMenuItem(
                          value: inv,
                          child: Text('${inv.invoiceNumber} - ${inv.customerName ?? ''}'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedInvoice = v),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                          child: Text(_selectedDate ?? ''),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonCtrl,
                        decoration: const InputDecoration(labelText: 'Reason *', border: OutlineInputBorder()),
                        maxLines: 2,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount *', border: OutlineInputBorder(), prefixText: '₹'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gstCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'GST Adjustment', border: OutlineInputBorder(), prefixText: '₹'),
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
              'note_type': _noteType,
              'invoice': _selectedInvoice?.id,
              'date': _selectedDate,
              'reason': _reasonCtrl.text,
              'amount': double.tryParse(_amountCtrl.text) ?? 0,
              'gst_adjustment': double.tryParse(_gstCtrl.text) ?? 0,
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
