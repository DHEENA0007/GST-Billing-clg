class UserModel {
  final int? id;
  final String? username;
  final String? email;
  final String? phone;
  final String? role;
  final String? firstName;
  final String? lastName;
  final bool? isActive;

  UserModel({this.id, this.username, this.email, this.phone, this.role, this.firstName, this.lastName, this.isActive});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'] ?? profile?['phone'],
      role: json['role'] ?? profile?['role'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'phone': phone,
        'role': role,
      };
}

class CompanySettings {
  final int? id;
  final String? companyName;
  final String? gstin;
  final String? address;
  final String? stateCode;
  final String? phone;
  final String? email;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? financialYear;
  final String? invoicePrefix;

  CompanySettings({
    this.id,
    this.companyName,
    this.gstin,
    this.address,
    this.stateCode,
    this.phone,
    this.email,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.financialYear,
    this.invoicePrefix,
  });

  factory CompanySettings.fromJson(Map<String, dynamic> json) => CompanySettings(
        id: json['id'],
        companyName: json['company_name'],
        gstin: json['gstin'],
        address: json['address'],
        stateCode: json['state_code'],
        phone: json['phone'],
        email: json['email'],
        bankName: json['bank_name'],
        accountNumber: json['account_number'],
        ifscCode: json['ifsc_code'],
        financialYear: json['financial_year'],
        invoicePrefix: json['invoice_prefix'],
      );

  Map<String, dynamic> toJson() => {
        'company_name': companyName,
        'gstin': gstin,
        'address': address,
        'state_code': stateCode,
        'phone': phone,
        'email': email,
        'bank_name': bankName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'financial_year': financialYear,
        'invoice_prefix': invoicePrefix,
      };
}

class Customer {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? shippingAddress;
  final String? gstin;
  final String? stateCode;

  Customer({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.shippingAddress,
    this.gstin,
    this.stateCode,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        address: json['address'],
        shippingAddress: json['shipping_address'],
        gstin: json['gstin'],
        stateCode: json['state_code'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'shipping_address': shippingAddress,
        'gstin': gstin,
        'state_code': stateCode,
      };
}

class Vendor {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? gstin;
  final String? stateCode;

  Vendor({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.gstin,
    this.stateCode,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        address: json['address'],
        gstin: json['gstin'],
        stateCode: json['state_code'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'gstin': gstin,
        'state_code': stateCode,
      };
}

class Product {
  final int? id;
  final String? name;
  final String? description;
  final String? hsnSac;
  final double? price;
  final double? gstRate;
  final String? unit;
  final int? stock;
  final int? lowStockThreshold;

  Product({
    this.id,
    this.name,
    this.description,
    this.hsnSac,
    this.price,
    this.gstRate,
    this.unit,
    this.stock,
    this.lowStockThreshold,
  });

  bool get isLowStock =>
      stock != null &&
      lowStockThreshold != null &&
      stock! <= lowStockThreshold!;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        hsnSac: json['hsn_sac'],
        price: _toDouble(json['price']),
        gstRate: _toDouble(json['gst_rate']),
        unit: json['unit'],
        stock: json['stock'],
        lowStockThreshold: json['low_stock_threshold'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'hsn_sac': hsnSac,
        'price': price,
        'gst_rate': gstRate,
        'unit': unit,
        'stock': stock,
        'low_stock_threshold': lowStockThreshold,
      };
}

class InvoiceItem {
  final int? id;
  final int? productId;
  final String? productName;
  final String? description;
  final double? quantity;
  final double? unitPrice;
  final double? gstRate;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? igstAmount;
  final double? total;

  InvoiceItem({
    this.id,
    this.productId,
    this.productName,
    this.description,
    this.quantity,
    this.unitPrice,
    this.gstRate,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
    this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        id: json['id'],
        productId: json['product'],
        productName: json['product_name'],
        description: json['description'],
        quantity: _toDouble(json['quantity']),
        unitPrice: _toDouble(json['unit_price']),
        gstRate: _toDouble(json['gst_rate']),
        cgstAmount: _toDouble(json['cgst_amount']),
        sgstAmount: _toDouble(json['sgst_amount']),
        igstAmount: _toDouble(json['igst_amount']),
        total: _toDouble(json['total']),
      );

  Map<String, dynamic> toJson() => {
        'product': productId,
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'gst_rate': gstRate,
      };
}

class Invoice {
  final int? id;
  final String? invoiceNumber;
  final String? invoiceType;
  final String? status;
  final int? customerId;
  final String? customerName;
  final String? date;
  final String? dueDate;
  final double? subtotal;
  final double? cgstTotal;
  final double? sgstTotal;
  final double? igstTotal;
  final double? total;
  final double? amountPaid;
  final List<InvoiceItem>? items;

  Invoice({
    this.id,
    this.invoiceNumber,
    this.invoiceType,
    this.status,
    this.customerId,
    this.customerName,
    this.date,
    this.dueDate,
    this.subtotal,
    this.cgstTotal,
    this.sgstTotal,
    this.igstTotal,
    this.total,
    this.amountPaid,
    this.items,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'],
        invoiceNumber: json['invoice_number'],
        invoiceType: json['invoice_type'],
        status: json['status'],
        customerId: json['customer'] is Map ? json['customer']['id'] : json['customer'],
        customerName: json['customer'] is Map ? json['customer']['name'] : json['customer_name'],
        date: json['date'],
        dueDate: json['due_date'],
        subtotal: _toDouble(json['subtotal']),
        cgstTotal: _toDouble(json['cgst_total']),
        sgstTotal: _toDouble(json['sgst_total']),
        igstTotal: _toDouble(json['igst_total']),
        total: _toDouble(json['total']),
        amountPaid: _toDouble(json['amount_paid']),
        items: json['items'] != null
            ? (json['items'] as List).map((i) => InvoiceItem.fromJson(i)).toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'invoice_number': invoiceNumber,
        'invoice_type': invoiceType,
        'status': status,
        'customer': customerId,
        'date': date,
        'due_date': dueDate,
      };
}

class Payment {
  final int? id;
  final int? invoiceId;
  final String? invoiceNumber;
  final double? amount;
  final String? paymentMode;
  final String? paymentDate;
  final String? referenceNumber;
  final String? notes;

  Payment({
    this.id,
    this.invoiceId,
    this.invoiceNumber,
    this.amount,
    this.paymentMode,
    this.paymentDate,
    this.referenceNumber,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        invoiceId: json['invoice'] is Map ? json['invoice']['id'] : json['invoice'],
        invoiceNumber: json['invoice'] is Map ? json['invoice']['invoice_number'] : json['invoice_number'],
        amount: _toDouble(json['amount']),
        paymentMode: json['mode'],
        paymentDate: json['date'],
        referenceNumber: json['reference_number'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'invoice': invoiceId,
        'amount': amount,
        'mode': paymentMode,
        'date': paymentDate,
        'reference_number': referenceNumber,
        'notes': notes,
      };
}

class CreditDebitNote {
  final int? id;
  final String? noteNumber;
  final String? noteType;
  final int? invoiceId;
  final String? invoiceNumber;
  final String? date;
  final String? reason;
  final double? amount;
  final double? gstAdjustment;

  CreditDebitNote({
    this.id,
    this.noteNumber,
    this.noteType,
    this.invoiceId,
    this.invoiceNumber,
    this.date,
    this.reason,
    this.amount,
    this.gstAdjustment,
  });

  factory CreditDebitNote.fromJson(Map<String, dynamic> json) => CreditDebitNote(
        id: json['id'],
        noteNumber: json['note_number'],
        noteType: json['note_type'],
        invoiceId: json['invoice'] is Map ? json['invoice']['id'] : json['invoice'],
        invoiceNumber: json['invoice'] is Map ? json['invoice']['invoice_number'] : json['invoice_number'],
        date: json['date'],
        reason: json['reason'],
        amount: _toDouble(json['amount']),
        gstAdjustment: _toDouble(json['gst_adjustment']),
      );

  Map<String, dynamic> toJson() => {
        'note_type': noteType,
        'invoice': invoiceId,
        'date': date,
        'reason': reason,
        'amount': amount,
        'gst_adjustment': gstAdjustment,
      };
}

class AuditLog {
  final int? id;
  final String? user;
  final String? action;
  final String? model;
  final String? objectId;
  final String? details;
  final String? timestamp;
  final String? ipAddress;

  AuditLog({
    this.id,
    this.user,
    this.action,
    this.model,
    this.objectId,
    this.details,
    this.timestamp,
    this.ipAddress,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'],
        user: json['user'] is Map ? json['user']['username'] : json['user']?.toString(),
        action: json['action'],
        model: json['model_name'],
        objectId: json['object_id']?.toString(),
        details: json['details'],
        timestamp: json['timestamp'],
        ipAddress: json['ip_address'],
      );
}

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}
