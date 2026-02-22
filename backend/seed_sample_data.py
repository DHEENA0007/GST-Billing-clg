"""
Sample Data Seeder for GST Billing Application
Populates all modules with realistic Indian business data.

Usage: python manage.py shell < seed_sample_data.py
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth.models import User
from core.models import (
    UserProfile, CompanySettings, Customer, Vendor, Product,
    Invoice, InvoiceItem, Purchase, Payment, CreditDebitNote, AuditLog
)
from django.utils import timezone
from datetime import timedelta, date
from decimal import Decimal
import random

print("=" * 60)
print("🌱 GST Billing — Sample Data Seeder")
print("=" * 60)

# ========================================================================
# 1. COMPANY SETTINGS
# ========================================================================
print("\n📋 Setting up Company Profile...")
settings, _ = CompanySettings.objects.get_or_create(id=1)
settings.company_name = "Sri Lakshmi Enterprises"
settings.gstin = "29AABCU9603R1ZM"
settings.address = "No. 42, Industrial Area, Phase 2, Peenya, Bengaluru - 560058, Karnataka"
settings.state_code = "29"
settings.phone = "+91 80 2839 4567"
settings.email = "accounts@srilakshmi.com"
settings.bank_name = "State Bank of India"
settings.account_number = "39876543210"
settings.ifsc_code = "SBIN0001234"
settings.financial_year = "2025-2026"
settings.invoice_prefix = "SLE"
settings.save()
print(f"  ✅ Company: {settings.company_name} (GSTIN: {settings.gstin})")

# ========================================================================
# 2. USERS & ROLES
# ========================================================================
print("\n👥 Creating Team Members...")
team = [
    {"username": "priya_acc", "first_name": "Priya", "last_name": "Sharma", "email": "priya@srilakshmi.com", "role": "ACCOUNTANT", "phone": "+91 90123 45678"},
    {"username": "rahul_sales", "first_name": "Rahul", "last_name": "Kumar", "email": "rahul@srilakshmi.com", "role": "SALES", "phone": "+91 98765 12345"},
    {"username": "deepa_sales", "first_name": "Deepa", "last_name": "Nair", "email": "deepa@srilakshmi.com", "role": "SALES", "phone": "+91 87654 32100"},
]
for t in team:
    user, created = User.objects.get_or_create(username=t["username"], defaults={
        "first_name": t["first_name"], "last_name": t["last_name"], "email": t["email"]
    })
    if created:
        user.set_password("welcome123")
        user.save()
        UserProfile.objects.create(user=user, role=t["role"], phone=t["phone"])
        print(f"  ✅ {t['first_name']} {t['last_name']} — {t['role']} (@{t['username']} / welcome123)")
    else:
        print(f"  ⏭️  {t['username']} already exists")

# ========================================================================
# 3. CUSTOMERS
# ========================================================================
print("\n🏢 Adding Customers...")
customers_data = [
    {"name": "Tata Steel Limited", "email": "purchase@tatasteel.com", "phone": "+91 22 6665 8282",
     "address": "Bombay House, 24 Homi Mody Street, Mumbai - 400001", "gstin": "27AAACT2727Q1ZB", "state_code": "27",
     "shipping_address": "Tata Steel Plant, Jamshedpur - 831001, Jharkhand"},
    {"name": "Infosys Technologies Pvt Ltd", "email": "vendor.mgmt@infosys.com", "phone": "+91 80 2852 0261",
     "address": "Electronics City, Hosur Road, Bengaluru - 560100", "gstin": "29AABCI8752H1Z9", "state_code": "29",
     "shipping_address": "Plot 44, Electronics City Phase 1, Bengaluru - 560100"},
    {"name": "Reliance Industries Ltd", "email": "accounts@ril.com", "phone": "+91 22 3555 5000",
     "address": "Maker Chambers IV, Nariman Point, Mumbai - 400021", "gstin": "27AABCR0123M1ZX", "state_code": "27",
     "shipping_address": "Reliance Corporate Park, Navi Mumbai - 400701"},
    {"name": "Bharat Electronics Ltd", "email": "purchase@bel.co.in", "phone": "+91 80 2503 9200",
     "address": "Outer Ring Road, Nagavara, Bengaluru - 560045", "gstin": "29AABCB5765R1Z4", "state_code": "29",
     "shipping_address": "BEL Factory, Jalahalli, Bengaluru - 560013"},
    {"name": "Wipro Limited", "email": "procurement@wipro.com", "phone": "+91 80 2844 0011",
     "address": "Doddakannelli, Sarjapur Road, Bengaluru - 560035", "gstin": "29AABCW8514M1Z2", "state_code": "29",
     "shipping_address": "Wipro Campus, Electronic City, Bengaluru - 560100"},
    {"name": "Mahindra & Mahindra Ltd", "email": "vendorpay@mahindra.com", "phone": "+91 22 2490 1441",
     "address": "Gateway Building, Apollo Bunder, Mumbai - 400001", "gstin": "27AABCM0123N1ZY", "state_code": "27",
     "shipping_address": "Mahindra Towers, Worli, Mumbai - 400018"},
    {"name": "Chennai Silks", "email": "accounts@chennaisilks.com", "phone": "+91 44 2852 3456",
     "address": "123, T Nagar, Chennai - 600017", "gstin": "33AABCC1234D1Z5", "state_code": "33",
     "shipping_address": "45, Anna Nagar, Chennai - 600040"},
    {"name": "Ramesh Traders", "email": "ramesh.traders@gmail.com", "phone": "+91 98451 23456",
     "address": "Shop 12, SP Road, Bengaluru - 560002", "gstin": "29AADFR9876T1Z3", "state_code": "29",
     "shipping_address": ""},
]

customers = []
for cd in customers_data:
    c, created = Customer.objects.get_or_create(name=cd["name"], defaults=cd)
    customers.append(c)
    status = "✅" if created else "⏭️ "
    print(f"  {status} {c.name} (GSTIN: {c.gstin}, State: {c.state_code})")

# ========================================================================
# 4. VENDORS / SUPPLIERS
# ========================================================================
print("\n🏭 Adding Vendors/Suppliers...")
vendors_data = [
    {"name": "Jindal Steel & Power", "email": "sales@jindalsteel.com", "phone": "+91 11 4146 1000",
     "address": "Jindal Centre, 12 Bhikaiji Cama Place, New Delhi - 110066", "gstin": "07AABCJ1234K1Z2", "state_code": "07"},
    {"name": "Ambuja Raw Materials", "email": "supply@ambuja.com", "phone": "+91 80 4123 4567",
     "address": "45, Whitefield Main Road, Bengaluru - 560066", "gstin": "29AABCA5678L1Z5", "state_code": "29"},
    {"name": "KCP Cement Ltd", "email": "orders@kcpcement.com", "phone": "+91 40 2323 4545",
     "address": "Ramky Towers, Hyderabad - 500034", "gstin": "36AABCK9101M1Z8", "state_code": "36"},
    {"name": "Supreme Industries", "email": "supply@supreme.co.in", "phone": "+91 22 2580 0000",
     "address": "601 Supreme Chambers, Off Veera Desai Road, Mumbai - 400053", "gstin": "27AABCS3456N1Z1", "state_code": "27"},
    {"name": "Asian Paints Distributors", "email": "bulk@asianpaints.com", "phone": "+91 22 3981 7000",
     "address": "6A Shantinagar, Santacruz, Mumbai - 400055", "gstin": "27AABCA7890P1Z6", "state_code": "27"},
]

vendors = []
for vd in vendors_data:
    v, created = Vendor.objects.get_or_create(name=vd["name"], defaults=vd)
    vendors.append(v)
    status = "✅" if created else "⏭️ "
    print(f"  {status} {v.name} (GSTIN: {v.gstin})")

# ========================================================================
# 5. PRODUCTS & SERVICES
# ========================================================================
print("\n📦 Adding Products & Services...")
products_data = [
    {"name": "MS Steel Plates (10mm)", "description": "Mild Steel plates, 10mm thickness, IS:2062 grade", "hsn_sac": "7208", "price": Decimal("4500.00"), "gst_rate": Decimal("18"), "unit": "KG", "stock": 2500, "low_stock_threshold": 500},
    {"name": "TMT Steel Bars (12mm)", "description": "Fe-500 grade TMT reinforcement bars", "hsn_sac": "7214", "price": Decimal("5800.00"), "gst_rate": Decimal("18"), "unit": "KG", "stock": 1800, "low_stock_threshold": 400},
    {"name": "Portland Cement (OPC 53)", "description": "Ordinary Portland Cement, 53 grade, 50kg bag", "hsn_sac": "2523", "price": Decimal("380.00"), "gst_rate": Decimal("28"), "unit": "PCS", "stock": 5000, "low_stock_threshold": 500},
    {"name": "PVC Pipes (4 inch)", "description": "UPVC pressure pipes, 4 inch diameter, 6m length", "hsn_sac": "3917", "price": Decimal("450.00"), "gst_rate": Decimal("18"), "unit": "PCS", "stock": 800, "low_stock_threshold": 100},
    {"name": "Electrical Cable (2.5 sqmm)", "description": "Copper conductor, PVC insulated, 2.5 sq mm, 90m coil", "hsn_sac": "8544", "price": Decimal("2200.00"), "gst_rate": Decimal("18"), "unit": "MTR", "stock": 3000, "low_stock_threshold": 300},
    {"name": "Exterior Emulsion Paint (20L)", "description": "Weatherproof exterior paint, 20 litre bucket", "hsn_sac": "3209", "price": Decimal("3500.00"), "gst_rate": Decimal("28"), "unit": "PCS", "stock": 150, "low_stock_threshold": 30},
    {"name": "Plumbing Consultation", "description": "Professional plumbing design & consultation service", "hsn_sac": "998399", "price": Decimal("5000.00"), "gst_rate": Decimal("18"), "unit": "HRS", "stock": 999, "low_stock_threshold": 0},
    {"name": "Civil Engineering Drawings", "description": "Structural engineering drawing & design service", "hsn_sac": "998332", "price": Decimal("15000.00"), "gst_rate": Decimal("18"), "unit": "NOS", "stock": 999, "low_stock_threshold": 0},
    {"name": "GI Wire (4mm)", "description": "Galvanized iron wire, 4mm diameter binding wire", "hsn_sac": "7217", "price": Decimal("85.00"), "gst_rate": Decimal("18"), "unit": "KG", "stock": 8, "low_stock_threshold": 50},
    {"name": "Sand (River)", "description": "Fine river sand for plastering, per cubic feet", "hsn_sac": "2505", "price": Decimal("55.00"), "gst_rate": Decimal("5"), "unit": "NOS", "stock": 3000, "low_stock_threshold": 500},
]

products = []
for pd in products_data:
    p, created = Product.objects.get_or_create(name=pd["name"], defaults=pd)
    products.append(p)
    status = "✅" if created else "⏭️ "
    print(f"  {status} {p.name} — ₹{p.price} + {p.gst_rate}% GST | Stock: {p.stock} {p.unit}")

# ========================================================================
# 6. INVOICES + LINE ITEMS
# ========================================================================
print("\n🧾 Creating Invoices...")
today = date.today()
admin_user = User.objects.filter(is_superuser=True).first()

invoices_data = [
    # Month 1 — 4 months ago
    {"inv": "SLE-2025-001", "customer": 0, "date": today - timedelta(days=120), "due": today - timedelta(days=90), "status": "PAID", "type": "TAX",
     "items": [(0, 500, Decimal("4500.00")), (2, 200, Decimal("380.00"))]},
    {"inv": "SLE-2025-002", "customer": 1, "date": today - timedelta(days=115), "due": today - timedelta(days=85), "status": "PAID", "type": "TAX",
     "items": [(4, 500, Decimal("2200.00")), (7, 2, Decimal("15000.00"))]},
    # Month 2 — 3 months ago
    {"inv": "SLE-2025-003", "customer": 2, "date": today - timedelta(days=90), "due": today - timedelta(days=60), "status": "PAID", "type": "TAX",
     "items": [(1, 300, Decimal("5800.00")), (3, 100, Decimal("450.00"))]},
    {"inv": "SLE-2025-004", "customer": 3, "date": today - timedelta(days=85), "due": today - timedelta(days=55), "status": "PAID", "type": "TAX",
     "items": [(0, 200, Decimal("4500.00")), (5, 20, Decimal("3500.00"))]},
    {"inv": "SLE-2025-005", "customer": 4, "date": today - timedelta(days=80), "due": today - timedelta(days=50), "status": "PAID", "type": "TAX",
     "items": [(6, 10, Decimal("5000.00")), (4, 200, Decimal("2200.00"))]},
    # Month 3 — 2 months ago
    {"inv": "SLE-2025-006", "customer": 5, "date": today - timedelta(days=60), "due": today - timedelta(days=30), "status": "PARTIAL", "type": "TAX",
     "items": [(2, 500, Decimal("380.00")), (9, 1000, Decimal("55.00"))]},
    {"inv": "SLE-2025-007", "customer": 6, "date": today - timedelta(days=55), "due": today - timedelta(days=25), "status": "PAID", "type": "TAX",
     "items": [(1, 150, Decimal("5800.00")), (8, 50, Decimal("85.00"))]},
    {"inv": "SLE-2025-008", "customer": 7, "date": today - timedelta(days=50), "due": today - timedelta(days=20), "status": "ISSUED", "type": "TAX",
     "items": [(3, 50, Decimal("450.00")), (5, 10, Decimal("3500.00"))]},
    # Month 4 — This month
    {"inv": "SLE-2025-009", "customer": 0, "date": today - timedelta(days=25), "due": today + timedelta(days=5), "status": "ISSUED", "type": "TAX",
     "items": [(0, 800, Decimal("4500.00")), (1, 400, Decimal("5800.00")), (2, 300, Decimal("380.00"))]},
    {"inv": "SLE-2025-010", "customer": 1, "date": today - timedelta(days=20), "due": today + timedelta(days=10), "status": "PARTIAL", "type": "TAX",
     "items": [(4, 600, Decimal("2200.00")), (6, 5, Decimal("5000.00"))]},
    {"inv": "SLE-2025-011", "customer": 3, "date": today - timedelta(days=15), "due": today + timedelta(days=15), "status": "ISSUED", "type": "TAX",
     "items": [(7, 3, Decimal("15000.00")), (9, 500, Decimal("55.00"))]},
    {"inv": "SLE-2025-012", "customer": 4, "date": today - timedelta(days=5), "due": today + timedelta(days=25), "status": "DRAFT", "type": "TAX",
     "items": [(5, 15, Decimal("3500.00")), (8, 100, Decimal("85.00"))]},
    # Proforma Invoice
    {"inv": "SLE-PRO-001", "customer": 2, "date": today - timedelta(days=3), "due": today + timedelta(days=30), "status": "DRAFT", "type": "PROFORMA",
     "items": [(0, 1000, Decimal("4500.00")), (2, 1000, Decimal("380.00")), (1, 500, Decimal("5800.00"))]},
    # Overdue invoice for alerts
    {"inv": "SLE-2025-013", "customer": 5, "date": today - timedelta(days=45), "due": today - timedelta(days=15), "status": "ISSUED", "type": "TAX",
     "items": [(3, 200, Decimal("450.00")), (4, 100, Decimal("2200.00"))]},
]

invoices = []
for inv_data in invoices_data:
    inv_num = inv_data["inv"]
    if Invoice.objects.filter(invoice_number=inv_num).exists():
        inv = Invoice.objects.get(invoice_number=inv_num)
        invoices.append(inv)
        print(f"  ⏭️  {inv_num} already exists")
        continue

    inv = Invoice.objects.create(
        invoice_type=inv_data["type"],
        invoice_number=inv_num,
        customer=customers[inv_data["customer"]],
        date=inv_data["date"],
        due_date=inv_data["due"],
        status=inv_data["status"],
        notes="Thank you for your business. Payment terms: Net 30 days." if inv_data["type"] == "TAX" else "This is a proforma invoice for your reference."
    )

    for prod_idx, qty, price in inv_data["items"]:
        prod = products[prod_idx]
        InvoiceItem.objects.create(
            invoice=inv, product=prod, description=prod.name,
            quantity=qty, unit_price=price, gst_rate=prod.gst_rate,
            subtotal=0, total=0  # Will be computed in save()
        )

    # Recalculate invoice totals
    inv.subtotal = sum(item.subtotal for item in inv.items.all())
    inv.cgst_total = sum(item.cgst_amount for item in inv.items.all())
    inv.sgst_total = sum(item.sgst_amount for item in inv.items.all())
    inv.igst_total = sum(item.igst_amount for item in inv.items.all())
    inv.total = sum(item.total for item in inv.items.all())
    inv.save()

    invoices.append(inv)
    print(f"  ✅ {inv_num} — {customers[inv_data['customer']].name} — ₹{inv.total:,.2f} [{inv_data['status']}]")

# ========================================================================
# 7. PAYMENTS
# ========================================================================
print("\n💳 Recording Payments...")
payment_modes = ['CASH', 'BANK', 'UPI', 'CARD', 'CHEQUE']

for inv in invoices:
    if inv.status == 'PAID':
        # Full payment
        Payment.objects.get_or_create(
            invoice=inv, amount=inv.total,
            defaults={
                "date": inv.date + timedelta(days=random.randint(5, 25)),
                "mode": random.choice(payment_modes),
                "reference_number": f"PAY-{random.randint(100000, 999999)}",
                "notes": f"Full payment for {inv.invoice_number}"
            }
        )
        print(f"  ✅ Full payment ₹{inv.total:,.2f} for {inv.invoice_number}")
    elif inv.status == 'PARTIAL':
        # Partial payment (50-70%)
        partial_pct = random.randint(50, 70) / 100
        partial_amt = (inv.total * Decimal(str(partial_pct))).quantize(Decimal("0.01"))
        Payment.objects.get_or_create(
            invoice=inv, amount=partial_amt,
            defaults={
                "date": inv.date + timedelta(days=random.randint(3, 15)),
                "mode": random.choice(payment_modes),
                "reference_number": f"PAY-{random.randint(100000, 999999)}",
                "notes": f"Partial payment for {inv.invoice_number}"
            }
        )
        # Update invoice amount_paid
        inv.amount_paid = partial_amt
        inv.save()
        print(f"  ✅ Partial payment ₹{partial_amt:,.2f} / ₹{inv.total:,.2f} for {inv.invoice_number}")

# ========================================================================
# 8. PURCHASES
# ========================================================================
print("\n🛒 Adding Purchase Orders...")
purchases_data = [
    {"po": "PO-2025-001", "vendor": 0, "date": today - timedelta(days=100), "subtotal": Decimal("250000"), "tax": Decimal("45000"), "total": Decimal("295000"), "itc": Decimal("45000")},
    {"po": "PO-2025-002", "vendor": 1, "date": today - timedelta(days=75), "subtotal": Decimal("180000"), "tax": Decimal("32400"), "total": Decimal("212400"), "itc": Decimal("32400")},
    {"po": "PO-2025-003", "vendor": 2, "date": today - timedelta(days=50), "subtotal": Decimal("95000"), "tax": Decimal("26600"), "total": Decimal("121600"), "itc": Decimal("26600")},
    {"po": "PO-2025-004", "vendor": 3, "date": today - timedelta(days=30), "subtotal": Decimal("120000"), "tax": Decimal("21600"), "total": Decimal("141600"), "itc": Decimal("21600")},
    {"po": "PO-2025-005", "vendor": 4, "date": today - timedelta(days=10), "subtotal": Decimal("85000"), "tax": Decimal("23800"), "total": Decimal("108800"), "itc": Decimal("23800")},
]

purchases = []
for pd_data in purchases_data:
    po, created = Purchase.objects.get_or_create(
        purchase_number=pd_data["po"],
        defaults={
            "vendor": vendors[pd_data["vendor"]],
            "date": pd_data["date"],
            "subtotal": pd_data["subtotal"],
            "tax_total": pd_data["tax"],
            "total": pd_data["total"],
            "input_tax_credit": pd_data["itc"],
            "status": "RECEIVED"
        }
    )
    purchases.append(po)
    status = "✅" if created else "⏭️ "
    print(f"  {status} {pd_data['po']} — {vendors[pd_data['vendor']].name} — ₹{pd_data['total']:,.2f}")

# Payments for purchases
for po in purchases:
    Payment.objects.get_or_create(
        purchase=po, amount=po.total,
        defaults={
            "date": po.date + timedelta(days=random.randint(5, 15)),
            "mode": random.choice(['BANK', 'CHEQUE']),
            "reference_number": f"PPAY-{random.randint(100000, 999999)}",
            "notes": f"Payment for {po.purchase_number}"
        }
    )

# ========================================================================
# 9. CREDIT / DEBIT NOTES
# ========================================================================
print("\n📝 Issuing Credit/Debit Notes...")
if invoices and len(invoices) > 2:
    notes_data = [
        {"type": "CREDIT", "num": "CN-2025-001", "invoice": invoices[0], "reason": "Goods returned — damaged MS Steel plates (50kg)", "amount": Decimal("225000"), "gst_adj": Decimal("40500")},
        {"type": "DEBIT", "num": "DN-2025-001", "invoice": invoices[2], "reason": "Additional freight charges for oversized delivery", "amount": Decimal("15000"), "gst_adj": Decimal("2700")},
        {"type": "CREDIT", "num": "CN-2025-002", "invoice": invoices[4], "reason": "Price adjustment as per revised rate contract", "amount": Decimal("25000"), "gst_adj": Decimal("4500")},
    ]
    for nd in notes_data:
        note, created = CreditDebitNote.objects.get_or_create(
            note_number=nd["num"],
            defaults={
                "note_type": nd["type"],
                "invoice": nd["invoice"],
                "date": today - timedelta(days=random.randint(5, 30)),
                "reason": nd["reason"],
                "amount": nd["amount"],
                "gst_adjustment": nd["gst_adj"]
            }
        )
        status = "✅" if created else "⏭️ "
        print(f"  {status} {nd['num']} ({nd['type']}) — ₹{nd['amount']:,.2f} — {nd['reason'][:50]}...")

# ========================================================================
# 10. AUDIT LOGS
# ========================================================================
print("\n📋 Generating Audit Trail...")
audit_entries = [
    {"action": "CREATE", "model": "CompanySettings", "details": "Company profile configured: Sri Lakshmi Enterprises"},
    {"action": "CREATE", "model": "Customer", "details": "Added customer: Tata Steel Limited (GSTIN: 27AAACT2727Q1ZB)"},
    {"action": "CREATE", "model": "Customer", "details": "Added customer: Infosys Technologies Pvt Ltd"},
    {"action": "CREATE", "model": "Product", "details": "Added product: MS Steel Plates (10mm) — HSN: 7208"},
    {"action": "CREATE", "model": "Product", "details": "Added product: Portland Cement (OPC 53) — HSN: 2523"},
    {"action": "CREATE", "model": "Invoice", "details": "Created invoice SLE-2025-001 for Tata Steel Limited — ₹22,50,000"},
    {"action": "UPDATE", "model": "Invoice", "details": "Invoice SLE-2025-001 status changed: DRAFT → ISSUED"},
    {"action": "CREATE", "model": "Payment", "details": "Payment received: ₹22,50,000 via Bank Transfer for SLE-2025-001"},
    {"action": "UPDATE", "model": "Invoice", "details": "Invoice SLE-2025-001 status changed: ISSUED → PAID"},
    {"action": "CREATE", "model": "Vendor", "details": "Added vendor: Jindal Steel & Power (GSTIN: 07AABCJ1234K1Z2)"},
    {"action": "CREATE", "model": "Purchase", "details": "Created purchase order PO-2025-001 for Jindal Steel & Power — ₹2,95,000"},
    {"action": "CREATE", "model": "CreditDebitNote", "details": "Credit note CN-2025-001 issued for SLE-2025-001 — ₹2,25,000"},
    {"action": "UPDATE", "model": "CompanySettings", "details": "Updated bank details: SBI A/C 39876543210, IFSC: SBIN0001234"},
    {"action": "CREATE", "model": "User", "details": "New user created: priya_acc (Accountant role)"},
    {"action": "CREATE", "model": "User", "details": "New user created: rahul_sales (Sales role)"},
]

if AuditLog.objects.count() == 0:
    for i, ae in enumerate(audit_entries):
        AuditLog.objects.create(
            user=admin_user,
            action=ae["action"],
            model_name=ae["model"],
            details=ae["details"],
            ip_address="192.168.1." + str(random.randint(10, 200))
        )
    print(f"  ✅ Created {len(audit_entries)} audit log entries")
else:
    print(f"  ⏭️  Audit logs already exist ({AuditLog.objects.count()} entries)")

# ========================================================================
# FINAL SUMMARY
# ========================================================================
print("\n" + "=" * 60)
print("✅ SAMPLE DATA SEEDING COMPLETE!")
print("=" * 60)
print(f"""
📊 Data Summary:
   • Company:          {CompanySettings.objects.first().company_name}
   • Users:            {User.objects.count()} (incl. admin)
   • Customers:        {Customer.objects.count()}
   • Vendors:          {Vendor.objects.count()}
   • Products:         {Product.objects.count()}
   • Invoices:         {Invoice.objects.count()} (Paid: {Invoice.objects.filter(status='PAID').count()}, Partial: {Invoice.objects.filter(status='PARTIAL').count()}, Issued: {Invoice.objects.filter(status='ISSUED').count()}, Draft: {Invoice.objects.filter(status='DRAFT').count()})
   • Payments:         {Payment.objects.count()}
   • Purchases:        {Purchase.objects.count()}
   • Credit/Debit:     {CreditDebitNote.objects.count()}
   • Audit Logs:       {AuditLog.objects.count()}

🔑 Login Credentials:
   • admin / password123      (Administrator)
   • priya_acc / welcome123   (Accountant)
   • rahul_sales / welcome123 (Sales)
   • deepa_sales / welcome123 (Sales)
""")
