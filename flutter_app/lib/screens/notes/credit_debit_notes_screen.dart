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
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Credit/Debit Notes',
      fab: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Note', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined, size: 80, color: Colors.grey[200]),
                          const SizedBox(height: 16),
                          const Text('No notes found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const Text('Create your first credit/debit note', style: TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: _notes.length,
                        itemBuilder: (context, i) {
                          final n = _notes[i];
                          final isCredit = n.noteType?.toLowerCase() == 'credit';
                          final accentColor = isCredit ? const Color(0xFF059669) : const Color(0xFFE11D48);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: accentColor.withOpacity(0.1), width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      isCredit ? Icons.add_chart_rounded : Icons.show_chart_rounded,
                                      color: accentColor,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              n.noteNumber ?? '-',
                                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: accentColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  n.noteType?.toUpperCase() ?? '',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (n.invoiceNumber != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.receipt_rounded, size: 12, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Text('Inv: ${n.invoiceNumber}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        if (n.reason != null)
                                          Text(
                                            n.reason!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${formatter.format(n.amount ?? 0)}',
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: accentColor, letterSpacing: -0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF6366F1)),
                                            onPressed: () => _showForm(existing: n),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_rounded, size: 20, color: Color(0xFFF43F5E)),
                                            onPressed: () => _delete(n),
                                            visualDensity: VisualDensity.compact,
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
    if (picked != null) setState(() => _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = _noteType.toLowerCase() == 'credit';
    final accentColor = isCredit ? const Color(0xFF059669) : const Color(0xFFE11D48);

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
                color: accentColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.8)],
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
                        child: Icon(isCredit ? Icons.add_chart_rounded : Icons.show_chart_rounded, color: Colors.white, size: 24),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.note != null ? 'Modify Adjustment' : 'Internal Ledger Adjustment',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCredit ? 'Increasing credit to customer account' : 'Issuing debit for customer account',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _isLoading
                  ? Container(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary),
                            const SizedBox(height: 16),
                            const Text('PREPARING DOCUMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
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
                            _buildSectionHeader('ADJUSTMENT TYPE'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildTypeButton(NoteTypes.credit, 'CREDIT', const Color(0xFF059669), Icons.add_circle_outline_rounded),
                                const SizedBox(width: 12),
                                _buildTypeButton(NoteTypes.debit, 'DEBIT', const Color(0xFFE11D48), Icons.remove_circle_outline_rounded),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeader('REFERENCE & VALUES'),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Invoice>(
                              isExpanded: true,
                              value: _selectedInvoice,
                              dropdownColor: Colors.white,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 13),
                              decoration: _inputDecoration('Link to Invoice', Icons.receipt_long_rounded),
                              items: _invoices.map((inv) => DropdownMenuItem(
                                value: inv,
                                child: Text('${inv.invoiceNumber} • ${inv.customerName ?? ''}', overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedInvoice = v),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _amountCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16),
                                    decoration: _inputDecoration('Adjustment Amount', Icons.currency_rupee_rounded),
                                    validator: (v) => v == null || v.isEmpty ? 'Amount is required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDate,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InputDecorator(
                                      decoration: _inputDecoration('Date', Icons.calendar_today_rounded),
                                      child: Text(_selectedDate != null ? DateFormat('dd MMM').format(DateTime.parse(_selectedDate!)) : '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _gstCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('GST Adjustment', Icons.calculate_rounded),
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeader('BUSINESS REASON'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _reasonCtrl,
                              decoration: _inputDecoration('Reason for Adjustment', Icons.info_outline_rounded).copyWith(hintText: 'e.g. Sales Return, Volume Discount...'),
                              maxLines: 2,
                              validator: (v) => v == null || v.isEmpty ? 'Reason is required' : null,
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
                          await widget.onSave({
                            'note_type': _noteType,
                            'invoice': _selectedInvoice?.id,
                            'date': _selectedDate,
                            'reason': _reasonCtrl.text,
                            'amount': double.tryParse(_amountCtrl.text) ?? 0,
                            'gst_adjustment': double.tryParse(_gstCtrl.text) ?? 0,
                          });
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFE11D48)));
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.note != null ? 'UPDATE DOCUMENT' : 'CREATE DOCUMENT', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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

  Widget _buildTypeButton(String type, String label, Color color, IconData icon) {
    bool isSelected = _noteType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _noteType = type),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : const Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isSelected ? color : const Color(0xFF64748B), letterSpacing: 1)),
            ],
          ),
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
