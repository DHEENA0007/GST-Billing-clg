import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  CompanySettings? _settings;
  bool _isLoading = true;

  // Company Profile controllers
  final _nameCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _selectedState;

  // Tax & Invoicing controllers
  String _financialYear = '2024-2025';
  final _invoicePrefixCtrl = TextEditingController();

  // Bank Details controllers
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCodeCtrl = TextEditingController();

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _isAdmin = auth.isAdmin;
    _tabController = TabController(
      length: _isAdmin ? 4 : 1,
      vsync: this,
    );
    if (_isAdmin) {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _invoicePrefixCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get(AppConstants.companySettings);
      Map<String, dynamic>? json;
      if (data is Map) {
        json = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty) {
        json = Map<String, dynamic>.from(data.first);
      }
      if (json != null) {
        final s = CompanySettings.fromJson(json);
        setState(() {
          _settings = s;
          _nameCtrl.text = s.companyName ?? '';
          _gstinCtrl.text = s.gstin ?? '';
          _addressCtrl.text = s.address ?? '';
          _phoneCtrl.text = s.phone ?? '';
          _emailCtrl.text = s.email ?? '';
          _selectedState = s.stateCode;
          _financialYear = s.financialYear ?? '2025-2026';
          _invoicePrefixCtrl.text = s.invoicePrefix ?? '';
          _bankNameCtrl.text = s.bankName ?? '';
          _accountNumberCtrl.text = s.accountNumber ?? '';
          _ifscCodeCtrl.text = s.ifscCode ?? '';
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _patchSettings(Map<String, dynamic> data) async {
    if (_settings?.id == null) {
      await _api.post(AppConstants.companySettings, data: data);
    } else {
      await _api.patch(
          '${AppConstants.companySettings}${_settings!.id}/', data: data);
    }
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return AppScaffold(
        title: 'Settings',
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.lock), text: 'Change Password'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChangePasswordTab(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: 'Settings',
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.business), text: 'Company Profile'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Tax & Invoicing'),
                Tab(icon: Icon(Icons.account_balance), text: 'Bank Details'),
                Tab(icon: Icon(Icons.lock), text: 'Change Password'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _CompanyProfileTab(
                        nameCtrl: _nameCtrl,
                        gstinCtrl: _gstinCtrl,
                        addressCtrl: _addressCtrl,
                        phoneCtrl: _phoneCtrl,
                        emailCtrl: _emailCtrl,
                        selectedState: _selectedState,
                        onStateChanged: (v) =>
                            setState(() => _selectedState = v),
                        onSave: () async {
                          await _patchSettings({
                            'company_name': _nameCtrl.text,
                            'gstin': _gstinCtrl.text,
                            'address': _addressCtrl.text,
                            'phone': _phoneCtrl.text,
                            'email': _emailCtrl.text,
                            'state_code': _selectedState,
                          });
                        },
                      ),
                      _TaxInvoicingTab(
                        financialYear: _financialYear,
                        invoicePrefixCtrl: _invoicePrefixCtrl,
                        onFinancialYearChanged: (v) =>
                            setState(() => _financialYear = v!),
                        onSave: () async {
                          await _patchSettings({
                            'financial_year': _financialYear,
                            'invoice_prefix': _invoicePrefixCtrl.text,
                          });
                        },
                      ),
                      _BankDetailsTab(
                        bankNameCtrl: _bankNameCtrl,
                        accountNumberCtrl: _accountNumberCtrl,
                        ifscCodeCtrl: _ifscCodeCtrl,
                        onSave: () async {
                          await _patchSettings({
                            'bank_name': _bankNameCtrl.text,
                            'account_number': _accountNumberCtrl.text,
                            'ifsc_code': _ifscCodeCtrl.text,
                          });
                        },
                      ),
                      _ChangePasswordTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Company Profile ──────────────────────────────────────────────────

class _CompanyProfileTab extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController gstinCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final String? selectedState;
  final ValueChanged<String?> onStateChanged;
  final Future<void> Function() onSave;

  const _CompanyProfileTab({
    required this.nameCtrl,
    required this.gstinCtrl,
    required this.addressCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.selectedState,
    required this.onStateChanged,
    required this.onSave,
  });

  @override
  State<_CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<_CompanyProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Company Profile',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: widget.nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Company Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business)),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Company name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: widget.gstinCtrl,
                  decoration: const InputDecoration(
                      labelText: 'GSTIN *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                      hintText: '15-character GSTIN'),
                  maxLength: 15,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'GSTIN is required';
                    if (v.length != 15) return 'GSTIN must be exactly 15 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: widget.selectedState,
                  decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on)),
                  isExpanded: true,
                  items: IndianStates.states
                      .map((s) => DropdownMenuItem(
                            value: s['code'],
                            child: Text('${s['code']} - ${s['name']}'),
                          ))
                      .toList(),
                  onChanged: widget.onStateChanged,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: widget.addressCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                      alignLabelWithHint: true),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: widget.phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: widget.emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: const Text('Update Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab 2: Tax & Invoicing ──────────────────────────────────────────────────

class _TaxInvoicingTab extends StatefulWidget {
  final String financialYear;
  final TextEditingController invoicePrefixCtrl;
  final ValueChanged<String?> onFinancialYearChanged;
  final Future<void> Function() onSave;

  const _TaxInvoicingTab({
    required this.financialYear,
    required this.invoicePrefixCtrl,
    required this.onFinancialYearChanged,
    required this.onSave,
  });

  @override
  State<_TaxInvoicingTab> createState() => _TaxInvoicingTabState();
}

class _TaxInvoicingTabState extends State<_TaxInvoicingTab> {
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tax & Invoicing Settings',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: widget.financialYear,
                decoration: const InputDecoration(
                    labelText: 'Financial Year',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today)),
                items: const [
                  DropdownMenuItem(
                      value: '2023-2024', child: Text('2023-2024')),
                  DropdownMenuItem(
                      value: '2024-2025', child: Text('2024-2025')),
                  DropdownMenuItem(
                      value: '2025-2026', child: Text('2025-2026')),
                  DropdownMenuItem(
                      value: '2026-2027', child: Text('2026-2027')),
                ],
                onChanged: widget.onFinancialYearChanged,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: widget.invoicePrefixCtrl,
                decoration: const InputDecoration(
                    labelText: 'Invoice Prefix',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt),
                    hintText: 'e.g. INV'),
                onChanged: (v) => setState(() {}),
              ),
              const SizedBox(height: 4),
              Text(
                'Preview: ${widget.invoicePrefixCtrl.text.isEmpty ? "INV" : widget.invoicePrefixCtrl.text}-000001',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: 'INR - Indian Rupee',
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                    fillColor: Color(0xFFF5F5F5),
                    filled: true),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: 'CGST + SGST / IGST',
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Tax Regime',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                    fillColor: Color(0xFFF5F5F5),
                    filled: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 3: Bank Details ─────────────────────────────────────────────────────

class _BankDetailsTab extends StatefulWidget {
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController ifscCodeCtrl;
  final Future<void> Function() onSave;

  const _BankDetailsTab({
    required this.bankNameCtrl,
    required this.accountNumberCtrl,
    required this.ifscCodeCtrl,
    required this.onSave,
  });

  @override
  State<_BankDetailsTab> createState() => _BankDetailsTabState();
}

class _BankDetailsTabState extends State<_BankDetailsTab> {
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bank details saved successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bank Details',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              TextFormField(
                controller: widget.bankNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: widget.accountNumberCtrl,
                decoration: const InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: widget.ifscCodeCtrl,
                decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code)),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('Save Bank Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 4: Change Password ──────────────────────────────────────────────────

class _ChangePasswordTab extends StatefulWidget {
  @override
  State<_ChangePasswordTab> createState() => _ChangePasswordTabState();
}

class _ChangePasswordTabState extends State<_ChangePasswordTab> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success =
        await auth.changePassword(_oldCtrl.text, _newCtrl.text);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green),
      );
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.error ?? 'Failed to change password'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Password',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _oldCtrl,
                  obscureText: _obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOld
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Enter current password'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter new password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm password';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _changePassword,
                    icon: auth.isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: const Text('Update Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
