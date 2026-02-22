from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CustomerViewSet, ProductViewSet, InvoiceViewSet, InvoiceItemViewSet,
    CompanySettingsViewSet, VendorViewSet, PurchaseViewSet, PaymentViewSet,
    CreditDebitNoteViewSet, AuditLogViewSet, ReportsViewSet
)
from .role_views import RoleManagementViewSet

router = DefaultRouter()
router.register(r'company-settings', CompanySettingsViewSet, basename='company-settings')
router.register(r'vendors', VendorViewSet)
router.register(r'customers', CustomerViewSet)
router.register(r'products', ProductViewSet)
router.register(r'invoices', InvoiceViewSet)
router.register(r'invoice-items', InvoiceItemViewSet)
router.register(r'purchases', PurchaseViewSet)
router.register(r'payments', PaymentViewSet)
router.register(r'credit-debit-notes', CreditDebitNoteViewSet)
router.register(r'roles', RoleManagementViewSet, basename='roles')
router.register(r'audit-logs', AuditLogViewSet, basename='audit-logs')
router.register(r'reports', ReportsViewSet, basename='reports')

urlpatterns = [
    path('api/', include(router.urls)),
]
