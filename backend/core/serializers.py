from rest_framework import serializers
from .models import (
    Customer, Product, Invoice, InvoiceItem, CompanySettings, 
    Vendor, Purchase, Payment, CreditDebitNote, AuditLog
)

class CompanySettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanySettings
        fields = '__all__'

class VendorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vendor
        fields = '__all__'

class CustomerSerializer(serializers.ModelSerializer):
    total_outstanding = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = '__all__'

    def get_total_outstanding(self, obj):
        from django.db.models import Sum, F
        result = obj.invoices.exclude(status='CANCELLED').aggregate(
            outstanding=Sum(F('total') - F('amount_paid'))
        )
        return result['outstanding'] or 0

class ProductSerializer(serializers.ModelSerializer):
    is_low_stock = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = '__all__'

    def get_is_low_stock(self, obj):
        return obj.stock <= obj.low_stock_threshold

class InvoiceItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    product_hsn = serializers.CharField(source='product.hsn_sac', read_only=True)
    
    class Meta:
        model = InvoiceItem
        fields = '__all__'
        read_only_fields = ('subtotal', 'cgst_amount', 'sgst_amount', 'igst_amount', 'total')

class PaymentSerializer(serializers.ModelSerializer):
    invoice_number = serializers.CharField(source='invoice.invoice_number', read_only=True)

    class Meta:
        model = Payment
        fields = '__all__'

class CreditDebitNoteSerializer(serializers.ModelSerializer):
    invoice_number = serializers.CharField(source='invoice.invoice_number', read_only=True)
    note_number = serializers.CharField(max_length=50, required=False, allow_blank=True, default='')

    class Meta:
        model = CreditDebitNote
        fields = '__all__'

class InvoiceSerializer(serializers.ModelSerializer):
    items = InvoiceItemSerializer(many=True, read_only=True)
    customer_details = CustomerSerializer(source='customer', read_only=True)
    payments = PaymentSerializer(many=True, read_only=True)
    notes_list = CreditDebitNoteSerializer(source='credit_debit_notes', many=True, read_only=True)
    
    class Meta:
        model = Invoice
        fields = '__all__'
        read_only_fields = ('subtotal', 'cgst_total', 'sgst_total', 'igst_total', 'total', 'amount_paid')
        
    def create(self, validated_data):
        invoice = Invoice.objects.create(**validated_data)
        return invoice

class PurchaseSerializer(serializers.ModelSerializer):
    vendor_details = VendorSerializer(source='vendor', read_only=True)
    
    class Meta:
        model = Purchase
        fields = '__all__'

class AuditLogSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    ip_address = serializers.CharField(read_only=True)

    class Meta:
        model = AuditLog
        fields = '__all__'
