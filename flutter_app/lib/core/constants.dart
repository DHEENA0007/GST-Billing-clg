class AppConstants {
  static const String baseUrl = 'http://127.0.0.1:8000/api/';

  // Auth endpoints
  static const String login = 'auth/login/';
  static const String register = 'auth/register/';
  static const String profile = 'auth/profile/';
  static const String changePassword = 'auth/change-password/';
  static const String refreshToken = 'auth/token/refresh/';

  // Company
  static const String companySettings = 'company-settings/';

  // Core entities
  static const String customers = 'customers/';
  static const String vendors = 'vendors/';
  static const String products = 'products/';

  // Invoices
  static const String invoices = 'invoices/';
  static String invoiceAddItem(int id) => 'invoices/$id/add_item/';
  static String invoiceIssue(int id) => 'invoices/$id/issue/';
  static String invoiceCancel(int id) => 'invoices/$id/cancel/';
  static String invoicePdf(int id) => 'invoices/$id/pdf/';

  // Payments
  static const String payments = 'payments/';

  // Credit/Debit Notes
  static const String creditDebitNotes = 'credit-debit-notes/';

  // Reports
  static const String salesReport = 'reports/sales_report/';
  static const String purchaseReport = 'reports/purchase_report/';
  static const String gstSummary = 'reports/gst_summary/';
  static const String profitLoss = 'reports/profit_loss/';
  static const String customerOutstanding = 'reports/customer_outstanding/';
  static const String stockReport = 'reports/stock_report/';
  static const String taxLiability = 'reports/tax_liability/';
  static const String gstr1 = 'reports/gstr1/';
  static const String gstr3b = 'reports/gstr3b/';

  // AI
  static const String aiDashboard = 'ai/dashboard/';

  // Audit
  static const String auditLogs = 'audit-logs/';

  // Roles/Team
  static const String roles = 'roles/';

  // Preferences keys
  static const String tokenKey = 'jwt_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String userKey = 'user_data';
}

class IndianStates {
  static const List<Map<String, String>> states = [
    {'code': '01', 'name': 'Jammu & Kashmir'},
    {'code': '02', 'name': 'Himachal Pradesh'},
    {'code': '03', 'name': 'Punjab'},
    {'code': '04', 'name': 'Chandigarh'},
    {'code': '05', 'name': 'Uttarakhand'},
    {'code': '06', 'name': 'Haryana'},
    {'code': '07', 'name': 'Delhi'},
    {'code': '08', 'name': 'Rajasthan'},
    {'code': '09', 'name': 'Uttar Pradesh'},
    {'code': '10', 'name': 'Bihar'},
    {'code': '11', 'name': 'Sikkim'},
    {'code': '12', 'name': 'Arunachal Pradesh'},
    {'code': '13', 'name': 'Nagaland'},
    {'code': '14', 'name': 'Manipur'},
    {'code': '15', 'name': 'Mizoram'},
    {'code': '16', 'name': 'Tripura'},
    {'code': '17', 'name': 'Meghalaya'},
    {'code': '18', 'name': 'Assam'},
    {'code': '19', 'name': 'West Bengal'},
    {'code': '20', 'name': 'Jharkhand'},
    {'code': '21', 'name': 'Odisha'},
    {'code': '22', 'name': 'Chhattisgarh'},
    {'code': '23', 'name': 'Madhya Pradesh'},
    {'code': '24', 'name': 'Gujarat'},
    {'code': '25', 'name': 'Daman & Diu'},
    {'code': '26', 'name': 'Dadra & Nagar Haveli'},
    {'code': '27', 'name': 'Maharashtra'},
    {'code': '28', 'name': 'Andhra Pradesh (Old)'},
    {'code': '29', 'name': 'Karnataka'},
    {'code': '30', 'name': 'Goa'},
    {'code': '31', 'name': 'Lakshadweep'},
    {'code': '32', 'name': 'Kerala'},
    {'code': '33', 'name': 'Tamil Nadu'},
    {'code': '34', 'name': 'Puducherry'},
    {'code': '35', 'name': 'Andaman & Nicobar Islands'},
    {'code': '36', 'name': 'Telangana'},
    {'code': '37', 'name': 'Andhra Pradesh'},
    {'code': '38', 'name': 'Ladakh'},
  ];

  static String getStateName(String code) {
    final state = states.firstWhere(
      (s) => s['code'] == code,
      orElse: () => {'name': 'Unknown'},
    );
    return state['name'] ?? 'Unknown';
  }
}

class GstRates {
  static const List<double> rates = [0.0, 5.0, 12.0, 18.0, 28.0];
}

class PaymentModes {
  static const List<String> modes = [
    'Cash',
    'Bank Transfer',
    'UPI',
    'Card',
    'Cheque',
  ];
}

class UserRoles {
  static const String admin = 'Admin';
  static const String accountant = 'Accountant';
  static const String salesRep = 'Sales Rep';
  static const List<String> all = [admin, accountant, salesRep];
}

class InvoiceStatuses {
  static const String draft = 'Draft';
  static const String issued = 'Issued';
  static const String paid = 'Paid';
  static const String partial = 'Partial';
  static const String cancelled = 'Cancelled';
  static const List<String> all = [draft, issued, paid, partial, cancelled];
}

class InvoiceTypes {
  static const String taxInvoice = 'Tax Invoice';
  static const String proforma = 'Proforma Invoice';
  static const List<String> all = [taxInvoice, proforma];
}

class NoteTypes {
  static const String credit = 'CREDIT';
  static const String debit = 'DEBIT';
  static const List<String> all = [credit, debit];
}
