from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import uuid

class UserProfile(models.Model):
    ROLE_CHOICES = (
        ('ADMIN', 'Admin'),
        ('ACCOUNTANT', 'Accountant'),
        ('SALES', 'Sales'),
    )
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='SALES')
    phone = models.CharField(max_length=20, blank=True, null=True)

    def __str__(self):
        return f"{self.user.username} - {self.role}"

class CompanySettings(models.Model):
    company_name = models.CharField(max_length=255, default="My Company")
    gstin = models.CharField(max_length=15, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    state_code = models.CharField(max_length=2, default='29')
    phone = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    bank_name = models.CharField(max_length=100, blank=True, null=True)
    account_number = models.CharField(max_length=50, blank=True, null=True)
    ifsc_code = models.CharField(max_length=20, blank=True, null=True)
    financial_year = models.CharField(max_length=10, default='2025-26')
    invoice_prefix = models.CharField(max_length=10, default='INV')

    def __str__(self):
        return self.company_name

class Customer(models.Model):
    name = models.CharField(max_length=255)
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    shipping_address = models.TextField(blank=True, null=True)
    gstin = models.CharField(max_length=15, blank=True, null=True)
    state_code = models.CharField(max_length=2, default='29')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Vendor(models.Model):
    name = models.CharField(max_length=255)
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    gstin = models.CharField(max_length=15, blank=True, null=True)
    state_code = models.CharField(max_length=2, default='29')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Product(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    hsn_sac = models.CharField(max_length=20)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    gst_rate = models.DecimalField(max_digits=5, decimal_places=2)
    unit = models.CharField(max_length=20, default='PCS')
    stock = models.IntegerField(default=0)
    low_stock_threshold = models.IntegerField(default=10)

    def __str__(self):
        return self.name

class Invoice(models.Model):
    TYPE_CHOICES = (
        ('TAX', 'Tax Invoice'),
        ('PROFORMA', 'Proforma Invoice'),
    )
    STATUS_CHOICES = (
        ('DRAFT', 'Draft'),
        ('ISSUED', 'Issued'),
        ('PAID', 'Paid'),
        ('PARTIAL', 'Partial'),
        ('CANCELLED', 'Cancelled'),
    )
    invoice_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='TAX')
    invoice_number = models.CharField(max_length=50, unique=True)
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='invoices')
    date = models.DateField(default=timezone.now)
    due_date = models.DateField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    notes = models.TextField(blank=True, null=True)
    
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    cgst_total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    sgst_total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    igst_total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    amount_paid = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    
    # E-Invoice fields
    irn = models.CharField(max_length=255, blank=True, null=True)
    qr_code_data = models.TextField(blank=True, null=True)
    eway_bill_number = models.CharField(max_length=50, blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Invoice {self.invoice_number}"

class InvoiceItem(models.Model):
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True)
    description = models.CharField(max_length=255, blank=True, null=True)
    quantity = models.IntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    gst_rate = models.DecimalField(max_digits=5, decimal_places=2)
    
    subtotal = models.DecimalField(max_digits=12, decimal_places=2)
    cgst_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    sgst_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    igst_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2)

    def save(self, *args, **kwargs):
        self.subtotal = self.unit_price * self.quantity
        company = CompanySettings.objects.first()
        company_state = company.state_code if company else '29'
        customer_state = self.invoice.customer.state_code if self.invoice and self.invoice.customer else '29'
        
        tax_amount = self.subtotal * (self.gst_rate / 100)
        
        if company_state == customer_state:
            self.cgst_amount = tax_amount / 2
            self.sgst_amount = tax_amount / 2
            self.igst_amount = 0
        else:
            self.cgst_amount = 0
            self.sgst_amount = 0
            self.igst_amount = tax_amount
            
        self.total = self.subtotal + tax_amount
        super().save(*args, **kwargs)

class Purchase(models.Model):
    STATUS_CHOICES = (
        ('RECEIVED', 'Received'),
        ('RETURNED', 'Returned'),
    )
    purchase_number = models.CharField(max_length=50, unique=True)
    vendor = models.ForeignKey(Vendor, on_delete=models.CASCADE, related_name='purchases')
    date = models.DateField(default=timezone.now)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='RECEIVED')
    notes = models.TextField(blank=True, null=True)
    
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    input_tax_credit = models.DecimalField(max_digits=12, decimal_places=2, default=0)

class Payment(models.Model):
    PAYMENT_MODE_CHOICES = (
        ('CASH', 'Cash'),
        ('BANK', 'Bank Transfer'),
        ('UPI', 'UPI'),
        ('CARD', 'Card'),
        ('CHEQUE', 'Cheque'),
    )
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='payments', null=True, blank=True)
    purchase = models.ForeignKey(Purchase, on_delete=models.CASCADE, related_name='payments', null=True, blank=True)
    date = models.DateField(default=timezone.now)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    mode = models.CharField(max_length=20, choices=PAYMENT_MODE_CHOICES, default='BANK')
    reference_number = models.CharField(max_length=100, blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.invoice:
            self.invoice.amount_paid = sum([p.amount for p in self.invoice.payments.all()])
            if self.invoice.amount_paid >= self.invoice.total:
                self.invoice.status = 'PAID'
            elif self.invoice.amount_paid > 0:
                self.invoice.status = 'PARTIAL'
            self.invoice.save()

class CreditDebitNote(models.Model):
    TYPE_CHOICES = (
        ('CREDIT', 'Credit Note'),
        ('DEBIT', 'Debit Note'),
    )
    note_type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    note_number = models.CharField(max_length=50, unique=True)
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='credit_debit_notes')
    date = models.DateField(default=timezone.now)
    reason = models.TextField()
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    gst_adjustment = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.note_type} - {self.note_number}"

class AuditLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=50)
    model_name = models.CharField(max_length=50)
    object_id = models.CharField(max_length=50, blank=True, null=True)
    details = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(blank=True, null=True)

    def __str__(self):
        return f"{self.user} - {self.action} {self.model_name} at {self.timestamp}"

    class Meta:
        ordering = ['-timestamp']
