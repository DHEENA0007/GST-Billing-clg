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
      length: _isAdmin ? 5 : 1,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (_isAdmin != auth.isAdmin) {
      _isAdmin = auth.isAdmin;
      _tabController.dispose();
      _tabController = TabController(
        length: _isAdmin ? 5 : 1,
        vsync: this,
      );
      if (_isAdmin) {
        _loadSettings();
      }
    }
  }

  Future<void> _loadSettings() async {
    if (!_isAdmin) return;
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
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return AppScaffold(
      title: 'Settings',
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'PROFILE'),
                Tab(text: 'COMPANY'),
                Tab(text: 'TAXATION'),
                Tab(text: 'BANK'),
                Tab(text: 'SECURITY'),
              ],
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 4, color: theme.colorScheme.primary),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _isLoading && isAdmin
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _UserProfileTab(user: auth.user),
                        _CompanyProfileTab(
                          nameCtrl: _nameCtrl,
                          gstinCtrl: _gstinCtrl,
                          addressCtrl: _addressCtrl,
                          phoneCtrl: _phoneCtrl,
                          emailCtrl: _emailCtrl,
                          selectedState: _selectedState,
                          onStateChanged: (v) => setState(() => _selectedState = v),
                          isAdmin: isAdmin,
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
                          onFinancialYearChanged: (v) => setState(() => _financialYear = v!),
                          isAdmin: isAdmin,
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
                          isAdmin: isAdmin,
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
          ),
        ],
      ),
    );
  }
}

// ── Tab 0: User Profile ─────────────────────────────────────────────────────

class _UserProfileTab extends StatelessWidget {
  final UserModel? user;

  const _UserProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    (user?.username?[0] ?? 'U').toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user?.username ?? 'Username',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                Text(
                  user?.role?.toUpperCase() ?? 'USER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: 1),
                ),
                const SizedBox(height: 32),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 32),
                _InfoRow(icon: Icons.email_outlined, label: 'EMAIL ADDRESS', value: user?.email ?? 'Not provided'),
                const SizedBox(height: 24),
                _InfoRow(icon: Icons.phone_outlined, label: 'PHONE NUMBER', value: user?.phone ?? 'Not provided'),
                const SizedBox(height: 24),
                _InfoRow(icon: Icons.badge_outlined, label: 'FULL NAME', value: '${user?.firstName ?? ""} ${user?.lastName ?? ""}'.trim().isEmpty ? "Not set" : '${user?.firstName} ${user?.lastName}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          ],
        ),
      ],
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
  final bool isAdmin;
  final Future<void> Function() onSave;

  const _CompanyProfileTab({
    required this.nameCtrl,
    required this.gstinCtrl,
    required this.addressCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.selectedState,
    required this.onStateChanged,
    required this.isAdmin,
    required this.onSave,
  });

  @override
  State<_CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<_CompanyProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  Future<void> _save() async {
    if (!widget.isAdmin) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required to save changes')));
       return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (!widget.isAdmin)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange[100]!)),
                child: Row(
                  children: [
                    Icon(Icons.lock_person_rounded, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('VIEW ONLY MODE: You need administrative privileges to modify company details.', style: TextStyle(color: Colors.orange[900], fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            _SettingsCard(
              title: 'Business Identity',
              icon: Icons.business_rounded,
              color: Colors.indigo,
              children: [
                TextFormField(
                  controller: widget.nameCtrl,
                  readOnly: !widget.isAdmin,
                  decoration: const InputDecoration(labelText: 'COMPANY NAME', prefixIcon: Icon(Icons.business_rounded)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: widget.gstinCtrl,
                  readOnly: !widget.isAdmin,
                  decoration: const InputDecoration(labelText: 'GSTIN', prefixIcon: Icon(Icons.numbers_rounded), hintText: '15-digit code'),
                  maxLength: 15,
                  validator: (v) => v != null && v.isNotEmpty && v.length != 15 ? 'Must be 15 chars' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: widget.selectedState,
                  decoration: const InputDecoration(labelText: 'OPERATING STATE', prefixIcon: Icon(Icons.map_rounded)),
                  items: IndianStates.states.map((s) => DropdownMenuItem(value: s['code'], child: Text('${s['code']} - ${s['name']}'))).toList(),
                  onChanged: widget.isAdmin ? widget.onStateChanged : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsCard(
              title: 'Contact Information',
              icon: Icons.contact_emergency_rounded,
              color: Colors.blue,
              children: [
                TextFormField(
                  controller: widget.addressCtrl,
                  readOnly: !widget.isAdmin,
                  decoration: const InputDecoration(labelText: 'REGISTERED ADDRESS', prefixIcon: Icon(Icons.location_on_rounded), alignLabelWithHint: true),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: widget.phoneCtrl,
                  readOnly: !widget.isAdmin,
                  decoration: const InputDecoration(labelText: 'BUSINESS PHONE', prefixIcon: Icon(Icons.phone_rounded)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: widget.emailCtrl,
                  readOnly: !widget.isAdmin,
                  decoration: const InputDecoration(labelText: 'BUSINESS EMAIL', prefixIcon: Icon(Icons.email_rounded)),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (widget.isAdmin)
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text('UPDATE COMPANY PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
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
  final bool isAdmin;
  final Future<void> Function() onSave;

  const _TaxInvoicingTab({
    required this.financialYear,
    required this.invoicePrefixCtrl,
    required this.onFinancialYearChanged,
    required this.isAdmin,
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
          const SnackBar(content: Text('Configuration saved'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _SettingsCard(
            title: 'Invoicing Setup',
            icon: Icons.receipt_long_rounded,
            color: Colors.purple,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: widget.financialYear,
                decoration: const InputDecoration(labelText: 'FINANCIAL YEAR', prefixIcon: Icon(Icons.event_note_rounded)),
                items: ['2023-2024', '2024-2025', '2025-2026', '2026-2027'].map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: widget.isAdmin ? widget.onFinancialYearChanged : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: widget.invoicePrefixCtrl,
                readOnly: !widget.isAdmin,
                decoration: const InputDecoration(labelText: 'INVOICE PREFIX', prefixIcon: Icon(Icons.tag_rounded), hintText: 'e.g. INV'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 12),
                    Text(
                      'PREVIEW: ${widget.invoicePrefixCtrl.text.isEmpty ? "INV" : widget.invoicePrefixCtrl.text}-0001',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsCard(
            title: 'Statutory Compliance',
            icon: Icons.gavel_rounded,
            color: Colors.amber,
            children: [
              TextFormField(
                initialValue: 'Indian GST (CGST/SGST/IGST)',
                readOnly: true,
                decoration: const InputDecoration(labelText: 'TAX REGIME', prefixIcon: Icon(Icons.verified_user_rounded), filled: true, fillColor: Color(0xFFF8FAFC)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: 'INR - INDIAN RUPEE (₹)',
                readOnly: true,
                decoration: const InputDecoration(labelText: 'BASE CURRENCY', prefixIcon: Icon(Icons.currency_rupee_rounded), filled: true, fillColor: Color(0xFFF8FAFC)),
              ),
            ],
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : const Text('SAVE TAX CONFIGURATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab 3: Bank Details ─────────────────────────────────────────────────────

class _BankDetailsTab extends StatefulWidget {
  final TextEditingController bankNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController ifscCodeCtrl;
  final bool isAdmin;
  final Future<void> Function() onSave;

  const _BankDetailsTab({
    required this.bankNameCtrl,
    required this.accountNumberCtrl,
    required this.ifscCodeCtrl,
    required this.isAdmin,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank details updated'), backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _SettingsCard(
            title: 'Settlement Account',
            icon: Icons.account_balance_rounded,
            color: Colors.teal,
            children: [
              TextFormField(
                controller: widget.bankNameCtrl,
                readOnly: !widget.isAdmin,
                decoration: const InputDecoration(labelText: 'BANK NAME', prefixIcon: Icon(Icons.account_balance_rounded)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: widget.accountNumberCtrl,
                readOnly: !widget.isAdmin,
                decoration: const InputDecoration(labelText: 'ACCOUNT NUMBER', prefixIcon: Icon(Icons.credit_card_rounded)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: widget.ifscCodeCtrl,
                readOnly: !widget.isAdmin,
                decoration: const InputDecoration(labelText: 'IFSC CODE', prefixIcon: Icon(Icons.qr_code_rounded)),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('UPDATE BANK DETAILS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            ),
          ],
        ],
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
  bool _isSaving = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(_oldCtrl.text, _newCtrl.text);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated'), backgroundColor: Color(0xFF10B981)));
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Failed'), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SettingsCard(
              title: 'Access Credentials',
              icon: Icons.security_rounded,
              color: Colors.red,
              children: [
                TextFormField(
                  controller: _oldCtrl,
                  obscureText: _obscureOld,
                  decoration: InputDecoration(
                    labelText: 'CURRENT PASSWORD',
                    prefixIcon: const Icon(Icons.lock_person_rounded),
                    suffixIcon: IconButton(icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureOld = !_obscureOld)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'NEW PASSWORD',
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureNew = !_obscureNew)),
                  ),
                  validator: (v) => v != null && v.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'CONFIRM NEW PASSWORD',
                    prefixIcon: const Icon(Icons.shield_rounded),
                    suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  ),
                  validator: (v) => v != _newCtrl.text ? 'Mismatch' : null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _changePassword,
                icon: const Icon(Icons.security_update_good_rounded),
                label: const Text('UPDATE ACCESS KEYS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Components ──────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final MaterialColor color;
  final List<Widget> children;

  const _SettingsCard({required this.title, required this.icon, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color[700], size: 20),
              ),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}
