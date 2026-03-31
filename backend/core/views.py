from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Sum, F, Q, Count
from django.utils import timezone
from datetime import datetime, timedelta
import json
from .models import (
    Customer, Product, Invoice, InvoiceItem, 
    CompanySettings, Vendor, Purchase, Payment,
    CreditDebitNote, AuditLog
)
from .serializers import (
    CustomerSerializer, ProductSerializer, InvoiceSerializer, 
    InvoiceItemSerializer, CompanySettingsSerializer, 
    VendorSerializer, PurchaseSerializer, PaymentSerializer,
    CreditDebitNoteSerializer, AuditLogSerializer
)

def log_action(user, action, model_name, object_id=None, details=None):
    AuditLog.objects.create(
        user=user, action=action, model_name=model_name,
        object_id=str(object_id) if object_id else None, details=details
    )

class CompanySettingsViewSet(viewsets.ModelViewSet):
    queryset = CompanySettings.objects.all()
    serializer_class = CompanySettingsSerializer

    def list(self, request):
        settings = CompanySettings.objects.first()
        if not settings:
            settings = CompanySettings.objects.create()
        serializer = self.get_serializer(settings)
        return Response(serializer.data)

class VendorViewSet(viewsets.ModelViewSet):
    queryset = Vendor.objects.all().order_by('-created_at')
    serializer_class = VendorSerializer

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, 'CREATE', 'Vendor', obj.id, f'Created vendor: {obj.name}')

class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all().order_by('-created_at')
    serializer_class = CustomerSerializer

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, 'CREATE', 'Customer', obj.id, f'Created customer: {obj.name}')

    @action(detail=False, methods=['post'])
    def validate_gstin(self, request):
        gstin = request.data.get('gstin', '')
        import re
        pattern = r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$'
        is_valid = bool(re.match(pattern, gstin.upper()))
        return Response({'gstin': gstin, 'is_valid': is_valid})

    @action(detail=True, methods=['get'])
    def transaction_history(self, request, pk=None):
        customer = self.get_object()
        invoices = Invoice.objects.filter(customer=customer).order_by('-date')
        serializer = InvoiceSerializer(invoices, many=True)
        return Response(serializer.data)

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, 'CREATE', 'Product', obj.id, f'Created product: {obj.name}')

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        products = Product.objects.filter(stock__lte=F('low_stock_threshold'))
        serializer = self.get_serializer(products, many=True)
        return Response(serializer.data)

class InvoiceViewSet(viewsets.ModelViewSet):
    queryset = Invoice.objects.all().order_by('-date', '-id')
    serializer_class = InvoiceSerializer

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, 'CREATE', 'Invoice', obj.id, f'Created invoice: {obj.invoice_number}')

    def recalculate_totals(self, invoice):
        items = invoice.items.all()
        invoice.subtotal = items.aggregate(Sum('subtotal'))['subtotal__sum'] or 0
        invoice.cgst_total = items.aggregate(Sum('cgst_amount'))['cgst_amount__sum'] or 0
        invoice.sgst_total = items.aggregate(Sum('sgst_amount'))['sgst_amount__sum'] or 0
        invoice.igst_total = items.aggregate(Sum('igst_amount'))['igst_amount__sum'] or 0
        invoice.total = items.aggregate(Sum('total'))['total__sum'] or 0
        invoice.save()

    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        invoice = self.get_object()
        data = request.data
        product = Product.objects.get(id=data['product_id'])
        item = InvoiceItem.objects.create(
            invoice=invoice, product=product,
            quantity=data['quantity'],
            unit_price=data.get('unit_price', product.price),
            gst_rate=product.gst_rate
        )
        self.recalculate_totals(invoice)
        return Response({'status': 'Item added', 'item_id': item.id, 'invoice': InvoiceSerializer(invoice).data})

    @action(detail=True, methods=['delete'])
    def remove_item(self, request, pk=None):
        invoice = self.get_object()
        item_id = request.data.get('item_id')
        try:
            item = InvoiceItem.objects.get(id=item_id, invoice=invoice)
            item.delete()
            self.recalculate_totals(invoice)
            return Response({'status': 'Item removed', 'invoice': InvoiceSerializer(invoice).data})
        except InvoiceItem.DoesNotExist:
            return Response({'error': 'Item not found'}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        invoice = self.get_object()
        invoice.status = 'CANCELLED'
        invoice.save()
        log_action(request.user, 'CANCEL', 'Invoice', invoice.id, f'Cancelled invoice: {invoice.invoice_number}')
        return Response(InvoiceSerializer(invoice).data)

    @action(detail=True, methods=['post'])
    def issue(self, request, pk=None):
        invoice = self.get_object()
        invoice.status = 'ISSUED'
        invoice.save()
        log_action(request.user, 'ISSUE', 'Invoice', invoice.id, f'Issued invoice: {invoice.invoice_number}')
        return Response(InvoiceSerializer(invoice).data)

class InvoiceItemViewSet(viewsets.ModelViewSet):
    queryset = InvoiceItem.objects.all()
    serializer_class = InvoiceItemSerializer

class PurchaseViewSet(viewsets.ModelViewSet):
    queryset = Purchase.objects.all().order_by('-date')
    serializer_class = PurchaseSerializer

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, 'CREATE', 'Purchase', obj.id, f'Created purchase: {obj.purchase_number}')

class PaymentViewSet(viewsets.ModelViewSet):
    queryset = Payment.objects.all().order_by('-date')
    serializer_class = PaymentSerializer

    def perform_create(self, serializer):
        obj = serializer.save()
        try:
            log_action(self.request.user, 'CREATE', 'Payment', obj.id, f'Payment of {obj.amount}')
        except Exception:
            pass

class CreditDebitNoteViewSet(viewsets.ModelViewSet):
    queryset = CreditDebitNote.objects.all().order_by('-date')
    serializer_class = CreditDebitNoteSerializer

    def perform_create(self, serializer):
        obj = serializer.save()
        log_action(self.request.user, 'CREATE', 'CreditDebitNote', obj.id, f'{obj.note_type} note: {obj.note_number}')

class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer

class ReportsViewSet(viewsets.ViewSet):
    """Reports & Analytics endpoints"""

    @action(detail=False, methods=['get'])
    def sales_report(self, request):
        start = request.query_params.get('start', (timezone.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        end = request.query_params.get('end', timezone.now().strftime('%Y-%m-%d'))
        invoices = Invoice.objects.filter(date__gte=start, date__lte=end).exclude(status='CANCELLED')
        data = invoices.aggregate(
            total_sales=Sum('total'), total_cgst=Sum('cgst_total'),
            total_sgst=Sum('sgst_total'), total_igst=Sum('igst_total'),
            total_collected=Sum('amount_paid'),
            invoice_count=Count('id')
        )
        for k in data: data[k] = data[k] or 0
        return Response(data)

    @action(detail=False, methods=['get'])
    def purchase_report(self, request):
        start = request.query_params.get('start', (timezone.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        end = request.query_params.get('end', timezone.now().strftime('%Y-%m-%d'))
        purchases = Purchase.objects.filter(date__gte=start, date__lte=end)
        data = purchases.aggregate(
            total_purchases=Sum('total'), total_tax=Sum('tax_total'),
            total_itc=Sum('input_tax_credit'), purchase_count=Count('id')
        )
        for k in data: data[k] = data[k] or 0
        return Response(data)

    @action(detail=False, methods=['get'])
    def gst_summary(self, request):
        start = request.query_params.get('start', (timezone.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        end = request.query_params.get('end', timezone.now().strftime('%Y-%m-%d'))
        
        sales = Invoice.objects.filter(date__gte=start, date__lte=end).exclude(status='CANCELLED')
        purchases = Purchase.objects.filter(date__gte=start, date__lte=end)
        
        output_tax = sales.aggregate(
            cgst=Sum('cgst_total'), sgst=Sum('sgst_total'), igst=Sum('igst_total')
        )
        input_tax = purchases.aggregate(itc=Sum('input_tax_credit'))
        
        for k in output_tax: output_tax[k] = output_tax[k] or 0
        input_tax['itc'] = input_tax['itc'] or 0
        
        net_liability = (output_tax['cgst'] + output_tax['sgst'] + output_tax['igst']) - input_tax['itc']
        
        return Response({
            'output_tax': output_tax,
            'input_tax_credit': input_tax['itc'],
            'net_tax_liability': net_liability
        })

    @action(detail=False, methods=['get'])
    def profit_loss(self, request):
        start = request.query_params.get('start', (timezone.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        end = request.query_params.get('end', timezone.now().strftime('%Y-%m-%d'))
        
        revenue = Invoice.objects.filter(date__gte=start, date__lte=end).exclude(status='CANCELLED').aggregate(total=Sum('subtotal'))['total'] or 0
        expenses = Purchase.objects.filter(date__gte=start, date__lte=end).aggregate(total=Sum('subtotal'))['total'] or 0
        
        return Response({
            'revenue': revenue, 'expenses': expenses,
            'gross_profit': revenue - expenses,
            'profit_margin': round((revenue - expenses) / revenue * 100, 2) if revenue > 0 else 0
        })

    @action(detail=False, methods=['get'])
    def customer_outstanding(self, request):
        customers = Customer.objects.annotate(
            outstanding=Sum(F('invoices__total') - F('invoices__amount_paid'),
                          filter=Q(invoices__status__in=['ISSUED', 'PARTIAL']))
        ).filter(outstanding__gt=0).values('id', 'name', 'gstin', 'outstanding').order_by('-outstanding')
        return Response(list(customers))

    @action(detail=False, methods=['get'])
    def stock_report(self, request):
        products = Product.objects.all().values(
            'id', 'name', 'hsn_sac', 'stock', 'price', 'low_stock_threshold'
        ).order_by('stock')
        data = list(products)
        for p in data:
            p['stock_value'] = p['stock'] * float(p['price'])
            p['is_low_stock'] = p['stock'] <= p['low_stock_threshold']
        return Response(data)

    @action(detail=False, methods=['get'])
    def tax_liability(self, request):
        start = request.query_params.get('start', (timezone.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        end = request.query_params.get('end', timezone.now().strftime('%Y-%m-%d'))
        
        invoices = Invoice.objects.filter(date__gte=start, date__lte=end).exclude(status='CANCELLED')
        items = InvoiceItem.objects.filter(invoice__in=invoices)
        
        rate_wise = items.values('gst_rate').annotate(
            taxable_value=Sum('subtotal'),
            cgst=Sum('cgst_amount'), sgst=Sum('sgst_amount'), igst=Sum('igst_amount'),
            total_tax=Sum(F('cgst_amount') + F('sgst_amount') + F('igst_amount'))
        ).order_by('gst_rate')
        
        return Response(list(rate_wise))

    @action(detail=False, methods=['get'])
    def gstr1(self, request):
        """GSTR-1 data: All outward supplies"""
        start = request.query_params.get('start', (timezone.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        end = request.query_params.get('end', timezone.now().strftime('%Y-%m-%d'))
        
        invoices = Invoice.objects.filter(
            date__gte=start, date__lte=end, invoice_type='TAX'
        ).exclude(status__in=['DRAFT', 'CANCELLED']).select_related('customer')
        
        data = []
        for inv in invoices:
            data.append({
                'invoice_number': inv.invoice_number,
                'invoice_date': inv.date.strftime('%d-%m-%Y'),
                'customer_name': inv.customer.name,
                'customer_gstin': inv.customer.gstin or 'URP',
                'taxable_value': float(inv.subtotal),
                'cgst': float(inv.cgst_total),
                'sgst': float(inv.sgst_total),
                'igst': float(inv.igst_total),
                'total': float(inv.total),
                'place_of_supply': inv.customer.state_code,
            })
        
        return Response({
            'period': f"{start} to {end}",
            'total_invoices': len(data),
            'total_taxable_value': sum(d['taxable_value'] for d in data),
            'total_tax': sum(d['cgst'] + d['sgst'] + d['igst'] for d in data),
            'invoices': data
        })

    @action(detail=False, methods=['get'])
    def gstr3b(self, request):
        """GSTR-3B summary"""
        start = request.query_params.get('start', (timezone.now() - timedelta(days=30)).strftime('%Y-%m-%d'))
        end = request.query_params.get('end', timezone.now().strftime('%Y-%m-%d'))
        
        sales_tax = Invoice.objects.filter(
            date__gte=start, date__lte=end
        ).exclude(status__in=['DRAFT', 'CANCELLED']).aggregate(
            taxable=Sum('subtotal'), cgst=Sum('cgst_total'),
            sgst=Sum('sgst_total'), igst=Sum('igst_total')
        )
        
        itc = Purchase.objects.filter(
            date__gte=start, date__lte=end
        ).aggregate(itc=Sum('input_tax_credit'))
        
        for k in sales_tax: sales_tax[k] = sales_tax[k] or 0
        itc['itc'] = itc['itc'] or 0
        
        output = sales_tax['cgst'] + sales_tax['sgst'] + sales_tax['igst']
        
        return Response({
            'period': f"{start} to {end}",
            'outward_supplies': {
                'taxable_value': sales_tax['taxable'],
                'cgst': sales_tax['cgst'], 'sgst': sales_tax['sgst'],
                'igst': sales_tax['igst'], 'total_tax': output
            },
            'input_tax_credit': itc['itc'],
            'net_tax_payable': output - itc['itc'],
        })
