from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    CustomTokenObtainPairView, UserRegistrationView, CurrentUserView,
    UserViewSet, CustomerViewSet, MechanicViewSet, VehicleViewSet,
    ServiceCategoryViewSet, ServiceViewSet, BookingViewSet, RepairJobViewSet,
    DiagnosisViewSet, SparePartViewSet, PartUsageViewSet, EstimateViewSet,
    InvoiceViewSet, PaymentViewSet, ServiceHistoryViewSet,
    MaintenanceReminderViewSet, NotificationViewSet, ActivityLogViewSet
)

router = DefaultRouter()
router.register('users', UserViewSet, basename='user')
router.register('customers', CustomerViewSet, basename='customer')
router.register('mechanics', MechanicViewSet, basename='mechanic')
router.register('vehicles', VehicleViewSet, basename='vehicle')
router.register('categories', ServiceCategoryViewSet, basename='category')
router.register('services', ServiceViewSet, basename='service')
router.register('bookings', BookingViewSet, basename='booking')
router.register('repair-jobs', RepairJobViewSet, basename='repair-job')
router.register('diagnoses', DiagnosisViewSet, basename='diagnosis')
router.register('spare-parts', SparePartViewSet, basename='spare-part')
router.register('part-usages', PartUsageViewSet, basename='part-usage')
router.register('estimates', EstimateViewSet, basename='estimate')
router.register('invoices', InvoiceViewSet, basename='invoice')
router.register('payments', PaymentViewSet, basename='payment')
router.register('service-history', ServiceHistoryViewSet, basename='service-history')
router.register('reminders', MaintenanceReminderViewSet, basename='reminder')
router.register('notifications', NotificationViewSet, basename='notification')
router.register('activity-logs', ActivityLogViewSet, basename='activity-log')

urlpatterns = [
    # Auth Endpoints
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', UserRegistrationView.as_view(), name='user_register'),
    path('auth/me/', CurrentUserView.as_view(), name='user_me'),

    # ViewSet Router URLs
    path('', include(router.urls)),
]
