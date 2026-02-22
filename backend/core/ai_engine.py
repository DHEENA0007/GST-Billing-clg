"""
AI Engine for GST Billing Application
Provides intelligent insights, recommendations, alerts, and predictions
by analyzing historical business data from the database.
"""
from django.db.models import Sum, Avg, Count, F, Q, Max, Min
from django.utils import timezone
from datetime import timedelta, datetime
from decimal import Decimal
import math


class AIEngine:
    """Core AI Engine that processes business data and generates insights."""

    def __init__(self):
        from core.models import (
            Invoice, InvoiceItem, Customer, Product, Payment, 
            Purchase, Vendor, CompanySettings
        )
        self.Invoice = Invoice
        self.InvoiceItem = InvoiceItem
        self.Customer = Customer
        self.Product = Product
        self.Payment = Payment
        self.Purchase = Purchase
        self.Vendor = Vendor
        self.CompanySettings = CompanySettings

    # =========================================================================
    # 1. SMART ALERTS - Proactive business health warnings
    # =========================================================================

    def get_all_alerts(self):
        """Generate all active alerts across the system."""
        alerts = []
        alerts.extend(self._overdue_payment_alerts())
        alerts.extend(self._low_stock_alerts())
        alerts.extend(self._gst_filing_alerts())
        alerts.extend(self._anomaly_alerts())
        alerts.extend(self._cash_flow_alerts())
        alerts.extend(self._customer_risk_alerts())
        alerts.extend(self._high_outstanding_alerts())

        # Sort by severity: CRITICAL > WARNING > INFO
        severity_order = {'CRITICAL': 0, 'WARNING': 1, 'INFO': 2}
        alerts.sort(key=lambda x: severity_order.get(x['severity'], 3))
        return alerts

    def _overdue_payment_alerts(self):
        """Detect invoices that are past their due date."""
        alerts = []
        today = timezone.now().date()
        overdue = self.Invoice.objects.filter(
            due_date__lt=today,
            status__in=['ISSUED', 'PARTIAL']
        ).select_related('customer')

        for inv in overdue:
            days_overdue = (today - inv.due_date).days
            remaining = float(inv.total - inv.amount_paid)
            severity = 'CRITICAL' if days_overdue > 30 else 'WARNING'
            alerts.append({
                'type': 'OVERDUE_PAYMENT',
                'severity': severity,
                'title': f'Invoice {inv.invoice_number} is {days_overdue} days overdue',
                'message': f'₹{remaining:,.2f} pending from {inv.customer.name}. Due date was {inv.due_date.strftime("%d %b %Y")}.',
                'action': f'Follow up with {inv.customer.name} for payment',
                'data': {'invoice_id': inv.id, 'customer_id': inv.customer.id, 'days_overdue': days_overdue, 'amount': remaining}
            })
        return alerts

    def _low_stock_alerts(self):
        """Detect products below their low stock threshold."""
        alerts = []
        low_stock = self.Product.objects.filter(stock__lte=F('low_stock_threshold'))
        for p in low_stock:
            severity = 'CRITICAL' if p.stock == 0 else 'WARNING'
            alerts.append({
                'type': 'LOW_STOCK',
                'severity': severity,
                'title': f'{"Out of stock" if p.stock == 0 else "Low stock"}: {p.name}',
                'message': f'Current stock: {p.stock} {p.unit}. Threshold: {p.low_stock_threshold} {p.unit}.',
                'action': f'Reorder {p.name} from supplier',
                'data': {'product_id': p.id, 'stock': p.stock, 'threshold': p.low_stock_threshold}
            })
        return alerts

    def _gst_filing_alerts(self):
        """Remind about upcoming GST filing deadlines."""
        alerts = []
        today = timezone.now().date()
        
        # GSTR-1: Due on 11th of next month
        if today.day >= 1 and today.day <= 11:
            days_left = 11 - today.day
            severity = 'CRITICAL' if days_left <= 2 else 'WARNING' if days_left <= 5 else 'INFO'
            alerts.append({
                'type': 'GST_FILING',
                'severity': severity,
                'title': f'GSTR-1 filing due in {days_left} days',
                'message': f'GSTR-1 for the previous month is due by {today.month}/{11}/{today.year}. Ensure all sales invoices are recorded.',
                'action': 'Review and file GSTR-1 from Reports → GSTR-1 tab',
                'data': {'days_left': days_left, 'type': 'GSTR-1'}
            })

        # GSTR-3B: Due on 20th of next month
        if today.day >= 1 and today.day <= 20:
            days_left = 20 - today.day
            severity = 'CRITICAL' if days_left <= 2 else 'WARNING' if days_left <= 5 else 'INFO'
            alerts.append({
                'type': 'GST_FILING',
                'severity': severity,
                'title': f'GSTR-3B filing due in {days_left} days',
                'message': f'GSTR-3B return is due by the 20th. Net tax liability must be paid.',
                'action': 'Review and file GSTR-3B from Reports → GSTR-3B tab',
                'data': {'days_left': days_left, 'type': 'GSTR-3B'}
            })
        return alerts

    def _anomaly_alerts(self):
        """Detect unusual invoice amounts — possible data entry errors."""
        alerts = []
        invoices = self.Invoice.objects.exclude(status__in=['DRAFT', 'CANCELLED'])
        
        if invoices.count() < 5:
            return alerts

        stats = invoices.aggregate(avg_total=Avg('total'), max_total=Max('total'))
        avg = float(stats['avg_total'] or 0)
        
        if avg == 0:
            return alerts

        # Flag invoices > 3x average
        threshold = avg * 3
        anomalies = invoices.filter(total__gt=threshold).select_related('customer')
        
        for inv in anomalies[:3]:  # Limit to top 3
            ratio = float(inv.total) / avg
            alerts.append({
                'type': 'ANOMALY',
                'severity': 'WARNING',
                'title': f'Unusually high invoice: {inv.invoice_number}',
                'message': f'₹{float(inv.total):,.2f} is {ratio:.1f}x your average invoice of ₹{avg:,.2f}. Please verify.',
                'action': 'Review this invoice for data entry errors',
                'data': {'invoice_id': inv.id, 'amount': float(inv.total), 'average': avg, 'ratio': round(ratio, 1)}
            })
        return alerts

    def _cash_flow_alerts(self):
        """Warn if outgoing payments exceed incoming for the month."""
        alerts = []
        today = timezone.now().date()
        month_start = today.replace(day=1)
        
        incoming = self.Payment.objects.filter(
            date__gte=month_start, invoice__isnull=False
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
        
        outgoing = self.Payment.objects.filter(
            date__gte=month_start, purchase__isnull=False
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        if outgoing > incoming and incoming > 0:
            alerts.append({
                'type': 'CASH_FLOW',
                'severity': 'WARNING',
                'title': 'Negative cash flow this month',
                'message': f'Outgoing (₹{float(outgoing):,.2f}) exceeds incoming (₹{float(incoming):,.2f}). Net deficit: ₹{float(outgoing - incoming):,.2f}.',
                'action': 'Follow up on pending receivables or reduce expenses',
                'data': {'incoming': float(incoming), 'outgoing': float(outgoing)}
            })
        return alerts

    def _customer_risk_alerts(self):
        """Identify customers with consistently late payments."""
        alerts = []
        customers = self.Customer.objects.annotate(
            overdue_count=Count('invoices', filter=Q(
                invoices__due_date__lt=timezone.now().date(),
                invoices__status__in=['ISSUED', 'PARTIAL']
            ))
        ).filter(overdue_count__gte=2)

        for c in customers[:5]:
            alerts.append({
                'type': 'CUSTOMER_RISK',
                'severity': 'WARNING',
                'title': f'At-risk customer: {c.name}',
                'message': f'{c.overdue_count} overdue invoices. Consider stricter payment terms.',
                'action': f'Review payment terms for {c.name}',
                'data': {'customer_id': c.id, 'overdue_count': c.overdue_count}
            })
        return alerts

    def _high_outstanding_alerts(self):
        """Flag customers with very high outstanding amounts."""
        alerts = []
        customers = self.Customer.objects.annotate(
            outstanding=Sum(
                F('invoices__total') - F('invoices__amount_paid'),
                filter=Q(invoices__status__in=['ISSUED', 'PARTIAL'])
            )
        ).filter(outstanding__gt=0).order_by('-outstanding')[:3]

        for c in customers:
            owed = float(c.outstanding)
            if owed > 50000:
                alerts.append({
                    'type': 'HIGH_OUTSTANDING',
                    'severity': 'CRITICAL' if owed > 200000 else 'WARNING',
                    'title': f'High outstanding: {c.name}',
                    'message': f'₹{owed:,.2f} outstanding. This is a significant receivable risk.',
                    'action': 'Prioritize collection from this customer',
                    'data': {'customer_id': c.id, 'outstanding': owed}
                })
        return alerts

    # =========================================================================
    # 2. SMART RECOMMENDATIONS - AI-powered business suggestions
    # =========================================================================

    def get_recommendations(self):
        """Generate all business recommendations."""
        recs = []
        recs.extend(self._product_recommendations())
        recs.extend(self._customer_recommendations())
        recs.extend(self._pricing_recommendations())
        recs.extend(self._operational_recommendations())
        return recs

    def _product_recommendations(self):
        """Product-level intelligence."""
        recs = []
        
        # Best sellers analysis
        top_products = self.InvoiceItem.objects.values(
            'product__name', 'product__id'
        ).annotate(
            total_qty=Sum('quantity'),
            total_revenue=Sum('total')
        ).order_by('-total_revenue')[:5]

        if top_products:
            names = ', '.join([p['product__name'] for p in top_products[:3]])
            recs.append({
                'type': 'TOP_PRODUCTS',
                'category': 'Products',
                'icon': 'package',
                'title': 'Your Best Sellers',
                'message': f'Top revenue generators: {names}. Consider increasing stock for these items.',
                'impact': 'HIGH',
                'data': list(top_products)
            })

        # Slow-moving products
        all_products = self.Product.objects.all()
        for product in all_products:
            sold_qty = self.InvoiceItem.objects.filter(
                product=product,
                invoice__date__gte=timezone.now().date() - timedelta(days=90)
            ).aggregate(qty=Sum('quantity'))['qty'] or 0
            
            if sold_qty == 0 and product.stock > 0:
                recs.append({
                    'type': 'SLOW_MOVING',
                    'category': 'Products',
                    'icon': 'archive',
                    'title': f'Slow-moving: {product.name}',
                    'message': f'No sales in 90 days with {product.stock} units in stock (₹{float(product.stock * product.price):,.2f} value). Consider a discount or promotion.',
                    'impact': 'MEDIUM',
                    'data': {'product_id': product.id, 'stock_value': float(product.stock * product.price)}
                })
        return recs[:8]  # Limit total

    def _customer_recommendations(self):
        """Customer intelligence and segmentation."""
        recs = []
        
        # Customer segmentation
        customers = self.Customer.objects.annotate(
            total_spent=Sum('invoices__total', filter=Q(invoices__status__in=['PAID', 'PARTIAL', 'ISSUED'])),
            invoice_count=Count('invoices', filter=Q(invoices__status__in=['PAID', 'PARTIAL', 'ISSUED']))
        ).filter(total_spent__gt=0).order_by('-total_spent')

        if customers.count() >= 3:
            # Top customers
            top_3 = customers[:3]
            total_revenue = sum([float(c.total_spent or 0) for c in customers])
            top_3_revenue = sum([float(c.total_spent or 0) for c in top_3])
            
            if total_revenue > 0:
                pct = (top_3_revenue / total_revenue) * 100
                names = ', '.join([c.name for c in top_3])
                recs.append({
                    'type': 'TOP_CUSTOMERS',
                    'category': 'Customers',
                    'icon': 'crown',
                    'title': 'Your VIP Customers',
                    'message': f'{names} account for {pct:.0f}% of your revenue. Prioritize relationship management.',
                    'impact': 'HIGH',
                    'data': [{'name': c.name, 'spent': float(c.total_spent)} for c in top_3]
                })

        # Inactive customers (no invoice in 60+ days)
        cutoff = timezone.now().date() - timedelta(days=60)
        inactive = self.Customer.objects.annotate(
            last_invoice=Max('invoices__date')
        ).filter(last_invoice__lt=cutoff)

        if inactive.count() > 0:
            recs.append({
                'type': 'INACTIVE_CUSTOMERS',
                'category': 'Customers',
                'icon': 'user-x',
                'title': f'{inactive.count()} inactive customer(s)',
                'message': f'These customers haven\'t been billed in 60+ days. Re-engage to retain them.',
                'impact': 'MEDIUM',
                'data': [{'name': c.name, 'last_invoice': str(c.last_invoice)} for c in inactive[:5]]
            })
        return recs

    def _pricing_recommendations(self):
        """Pricing optimization suggestions based on sales velocity."""
        recs = []
        
        products = self.Product.objects.all()
        for product in products:
            # Calculate sales velocity (units per week over last 30 days)
            last_30 = self.InvoiceItem.objects.filter(
                product=product,
                invoice__date__gte=timezone.now().date() - timedelta(days=30)
            ).aggregate(qty=Sum('quantity'))['qty'] or 0
            
            weekly_velocity = last_30 / 4.3  # Approximate weeks

            # High demand + low stock = opportunity to increase price
            if weekly_velocity > 5 and product.stock < product.low_stock_threshold * 2:
                suggested_increase = min(15, max(5, int(weekly_velocity)))
                recs.append({
                    'type': 'PRICE_INCREASE',
                    'category': 'Pricing',
                    'icon': 'trending-up',
                    'title': f'Price increase opportunity: {product.name}',
                    'message': f'High demand ({weekly_velocity:.1f} units/week) with limited stock. Consider a {suggested_increase}% price increase.',
                    'impact': 'HIGH',
                    'data': {'product_id': product.id, 'velocity': round(weekly_velocity, 1), 'suggested_increase': suggested_increase}
                })
        return recs

    def _operational_recommendations(self):
        """Operational efficiency suggestions."""
        recs = []
        
        # Draft invoices sitting idle
        drafts = self.Invoice.objects.filter(status='DRAFT')
        if drafts.count() > 0:
            recs.append({
                'type': 'PENDING_DRAFTS',
                'category': 'Operations',
                'icon': 'file-text',
                'title': f'{drafts.count()} draft invoice(s) pending',
                'message': 'Review and issue these drafts to keep your books up to date.',
                'impact': 'LOW',
                'data': {'count': drafts.count()}
            })

        # Customers without GSTIN
        no_gstin = self.Customer.objects.filter(Q(gstin__isnull=True) | Q(gstin=''))
        if no_gstin.count() > 0:
            recs.append({
                'type': 'MISSING_GSTIN',
                'category': 'Compliance',
                'icon': 'alert-triangle',
                'title': f'{no_gstin.count()} customer(s) without GSTIN',
                'message': 'Collect GSTIN from these B2B customers for proper GST compliance and input tax credit.',
                'impact': 'MEDIUM',
                'data': [c.name for c in no_gstin[:5]]
            })
        return recs

    # =========================================================================
    # 3. PREDICTIVE ANALYTICS - Revenue forecasting & trend analysis
    # =========================================================================

    def get_predictions(self):
        """Generate business forecasts and predictions."""
        return {
            'revenue_forecast': self._revenue_forecast(),
            'payment_prediction': self._payment_delay_prediction(),
            'demand_forecast': self._demand_forecast(),
            'business_health_score': self._business_health_score(),
        }

    def _revenue_forecast(self):
        """Predict next month's revenue using linear regression on historical data."""
        today = timezone.now().date()
        monthly_data = []
        
        for i in range(6, 0, -1):
            month_start = (today - timedelta(days=30 * i)).replace(day=1)
            month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
            
            revenue = self.Invoice.objects.filter(
                date__gte=month_start, date__lte=month_end
            ).exclude(status__in=['DRAFT', 'CANCELLED']).aggregate(
                total=Sum('total')
            )['total'] or Decimal('0')
            
            monthly_data.append({
                'month': month_start.strftime('%b %Y'),
                'revenue': float(revenue)
            })

        # Simple linear regression for forecasting
        n = len(monthly_data)
        if n < 2 or all(d['revenue'] == 0 for d in monthly_data):
            return {'forecast': 0, 'trend': 'STABLE', 'confidence': 0, 'monthly_data': monthly_data}

        x_vals = list(range(n))
        y_vals = [d['revenue'] for d in monthly_data]
        
        x_mean = sum(x_vals) / n
        y_mean = sum(y_vals) / n
        
        num = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_vals, y_vals))
        den = sum((x - x_mean) ** 2 for x in x_vals)
        
        if den == 0:
            slope = 0
            intercept = y_mean
        else:
            slope = num / den
            intercept = y_mean - slope * x_mean

        forecast = max(0, intercept + slope * n)
        
        # Calculate trend percentage
        if y_mean > 0:
            trend_pct = (slope / y_mean) * 100
        else:
            trend_pct = 0

        trend = 'GROWING' if trend_pct > 5 else 'DECLINING' if trend_pct < -5 else 'STABLE'
        
        # Simple R² for confidence
        ss_res = sum((y - (intercept + slope * x)) ** 2 for x, y in zip(x_vals, y_vals))
        ss_tot = sum((y - y_mean) ** 2 for y in y_vals)
        r_squared = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0
        confidence = max(0, min(100, int(r_squared * 100)))

        return {
            'forecast': round(forecast, 2),
            'trend': trend,
            'trend_percentage': round(trend_pct, 1),
            'confidence': confidence,
            'monthly_data': monthly_data
        }

    def _payment_delay_prediction(self):
        """Predict average payment delays per customer."""
        predictions = []
        customers = self.Customer.objects.all()

        for customer in customers[:10]:
            paid_invoices = self.Invoice.objects.filter(
                customer=customer, status='PAID', due_date__isnull=False
            )
            
            if paid_invoices.count() == 0:
                continue

            delays = []
            for inv in paid_invoices:
                last_payment = inv.payments.order_by('-date').first()
                if last_payment and inv.due_date:
                    delay = (last_payment.date - inv.due_date).days
                    delays.append(delay)

            if delays:
                avg_delay = sum(delays) / len(delays)
                predictions.append({
                    'customer': customer.name,
                    'customer_id': customer.id,
                    'avg_delay_days': round(avg_delay, 1),
                    'risk_level': 'HIGH' if avg_delay > 15 else 'MEDIUM' if avg_delay > 5 else 'LOW',
                    'sample_size': len(delays)
                })

        predictions.sort(key=lambda x: x['avg_delay_days'], reverse=True)
        return predictions

    def _demand_forecast(self):
        """Forecast product demand based on recent sales trends."""
        forecasts = []
        products = self.Product.objects.all()

        for product in products:
            monthly_sales = []
            today = timezone.now().date()
            
            for i in range(3, 0, -1):
                start = today - timedelta(days=30 * i)
                end = today - timedelta(days=30 * (i - 1))
                qty = self.InvoiceItem.objects.filter(
                    product=product, invoice__date__gte=start, invoice__date__lt=end
                ).aggregate(qty=Sum('quantity'))['qty'] or 0
                monthly_sales.append(qty)

            # Simple moving average prediction
            if sum(monthly_sales) > 0:
                predicted = sum(monthly_sales) / len(monthly_sales)
                trend_dir = 'UP' if monthly_sales[-1] > monthly_sales[0] else 'DOWN' if monthly_sales[-1] < monthly_sales[0] else 'STABLE'
                
                weeks_of_stock = (product.stock / (predicted / 4.3)) if predicted > 0 else float('inf')
                
                forecasts.append({
                    'product': product.name,
                    'product_id': product.id,
                    'monthly_sales': monthly_sales,
                    'predicted_demand': round(predicted, 1),
                    'trend': trend_dir,
                    'current_stock': product.stock,
                    'weeks_of_stock': round(min(weeks_of_stock, 99), 1),
                    'reorder_urgent': weeks_of_stock < 2
                })

        forecasts.sort(key=lambda x: x['weeks_of_stock'])
        return forecasts

    def _business_health_score(self):
        """Calculate an overall business health score (0-100)."""
        score = 100
        factors = []
        today = timezone.now().date()

        # Factor 1: Collection efficiency (weight: 25)
        total_billed = float(self.Invoice.objects.exclude(
            status__in=['DRAFT', 'CANCELLED']
        ).aggregate(total=Sum('total'))['total'] or 0)
        
        total_collected = float(self.Invoice.objects.exclude(
            status__in=['DRAFT', 'CANCELLED']
        ).aggregate(total=Sum('amount_paid'))['total'] or 0)

        if total_billed > 0:
            collection_rate = (total_collected / total_billed) * 100
            collection_score = min(25, collection_rate * 0.25)
        else:
            collection_score = 25
            collection_rate = 100

        factors.append({'name': 'Collection Efficiency', 'score': round(collection_score, 1), 'max': 25, 'detail': f'{collection_rate:.0f}%'})

        # Factor 2: Overdue invoices (weight: 25)
        overdue_count = self.Invoice.objects.filter(
            due_date__lt=today, status__in=['ISSUED', 'PARTIAL']
        ).count()
        total_invoices = max(1, self.Invoice.objects.exclude(status__in=['DRAFT', 'CANCELLED']).count())
        overdue_rate = (overdue_count / total_invoices) * 100
        overdue_score = max(0, 25 - (overdue_rate * 0.5))
        factors.append({'name': 'Payment Compliance', 'score': round(overdue_score, 1), 'max': 25, 'detail': f'{overdue_count} overdue'})

        # Factor 3: Product stock health (weight: 25)
        total_products = max(1, self.Product.objects.count())
        low_stock = self.Product.objects.filter(stock__lte=F('low_stock_threshold')).count()
        stock_health = ((total_products - low_stock) / total_products) * 25
        factors.append({'name': 'Stock Health', 'score': round(stock_health, 1), 'max': 25, 'detail': f'{low_stock} low items'})

        # Factor 4: Customer diversity (weight: 25)
        active_customers = self.Customer.objects.annotate(
            inv_count=Count('invoices')
        ).filter(inv_count__gt=0).count()
        
        diversity_score = min(25, active_customers * 5)
        factors.append({'name': 'Customer Base', 'score': round(diversity_score, 1), 'max': 25, 'detail': f'{active_customers} active'})

        total_score = sum(f['score'] for f in factors)
        grade = 'A+' if total_score >= 90 else 'A' if total_score >= 80 else 'B' if total_score >= 65 else 'C' if total_score >= 50 else 'D'

        return {
            'score': round(total_score, 1),
            'grade': grade,
            'factors': factors,
            'summary': self._health_summary(total_score)
        }

    def _health_summary(self, score):
        """Generate a human-readable health summary."""
        if score >= 90:
            return "Excellent! Your business is running at peak efficiency. Keep up the great work."
        elif score >= 80:
            return "Very good. Minor improvements possible in payment collection or stock management."
        elif score >= 65:
            return "Good overall health but some areas need attention. Review alerts for specific actions."
        elif score >= 50:
            return "Fair. Several areas of concern detected. Focus on reducing overdue payments and improving cash flow."
        else:
            return "Needs immediate attention. Multiple critical issues detected. Address alerts urgently."

    # =========================================================================
    # 4. BUSINESS INSIGHTS - Data-driven intelligence
    # =========================================================================

    def get_insights(self):
        """Generate high-level business insights."""
        return {
            'revenue_by_month': self._monthly_revenue_trend(),
            'top_products_by_revenue': self._top_products(),
            'customer_segmentation': self._customer_segments(),
            'gst_breakdown': self._gst_breakdown(),
            'payment_mode_analysis': self._payment_modes(),
        }

    def _monthly_revenue_trend(self):
        """Monthly revenue for the last 6 months."""
        today = timezone.now().date()
        data = []
        for i in range(5, -1, -1):
            month_start = (today - timedelta(days=30 * i)).replace(day=1)
            month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
            
            stats = self.Invoice.objects.filter(
                date__gte=month_start, date__lte=month_end
            ).exclude(status__in=['DRAFT', 'CANCELLED']).aggregate(
                revenue=Sum('total'), count=Count('id')
            )
            data.append({
                'month': month_start.strftime('%b %Y'),
                'revenue': float(stats['revenue'] or 0),
                'invoices': stats['count'] or 0
            })
        return data

    def _top_products(self):
        """Top products by revenue."""
        return list(self.InvoiceItem.objects.values(
            'product__name'
        ).annotate(
            revenue=Sum('total'), quantity=Sum('quantity')
        ).order_by('-revenue')[:6])

    def _customer_segments(self):
        """Segment customers into tiers."""
        customers = self.Customer.objects.annotate(
            total_spent=Sum('invoices__total', filter=Q(invoices__status__in=['PAID', 'PARTIAL', 'ISSUED']))
        ).filter(total_spent__gt=0).order_by('-total_spent')

        segments = {'Platinum': [], 'Gold': [], 'Silver': [], 'Bronze': []}
        total = customers.count()
        
        for i, c in enumerate(customers):
            pct = (i / max(1, total)) * 100
            tier = 'Platinum' if pct < 10 else 'Gold' if pct < 30 else 'Silver' if pct < 60 else 'Bronze'
            segments[tier].append({'name': c.name, 'spent': float(c.total_spent or 0)})

        return {tier: {'count': len(custs), 'customers': custs[:5]} for tier, custs in segments.items()}

    def _gst_breakdown(self):
        """GST breakdown by rate."""
        return list(self.InvoiceItem.objects.values('gst_rate').annotate(
            taxable=Sum('subtotal'),
            tax=Sum(F('cgst_amount') + F('sgst_amount') + F('igst_amount'))
        ).order_by('-taxable'))

    def _payment_modes(self):
        """Analyze preferred payment methods."""
        return list(self.Payment.objects.filter(invoice__isnull=False).values('mode').annotate(
            count=Count('id'), total=Sum('amount')
        ).order_by('-total'))
