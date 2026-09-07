from rest_framework import viewsets, status, generics, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from django.http import HttpResponse
from django.db.models import Q
from django.utils import timezone
from decimal import Decimal
from .pdf_utils import generate_invoice_pdf

from .models import (
    User, Customer, Vehicle, ServiceCategory, Service, Mechanic, Booking,
    RepairJob, Diagnosis, SparePart, PartUsage, Estimate, Invoice, Payment,
    ServiceHistory, MaintenanceReminder, Notification, ActivityLog
)
from .serializers import (
    UserSerializer, UserRegistrationSerializer, CustomTokenObtainPairSerializer,
    CustomerSerializer, CustomerWriteSerializer,
    VehicleReadSerializer, VehicleWriteSerializer,
    ServiceCategorySerializer, ServiceReadSerializer, ServiceWriteSerializer,
    MechanicSerializer, MechanicWriteSerializer,
    BookingReadSerializer, BookingWriteSerializer,
    RepairJobReadSerializer, RepairJobWriteSerializer,
    DiagnosisSerializer, SparePartSerializer,
    PartUsageReadSerializer, PartUsageWriteSerializer,
    EstimateSerializer, InvoiceReadSerializer, InvoiceWriteSerializer,
    PaymentReadSerializer, PaymentWriteSerializer,
    ServiceHistoryReadSerializer, ServiceHistoryWriteSerializer,
    MaintenanceReminderSerializer, MaintenanceReminderWriteSerializer,
    NotificationSerializer, ActivityLogSerializer
)
from .permissions import IsAdmin, IsReceptionist, IsMechanic, IsCustomer, IsAdminOrReceptionist, IsStaffUser, IsOwnerOrStaff


# =============================================================================
# 1. AUTHENTICATION VIEWS
# =============================================================================

class CustomTokenObtainPairView(TokenObtainPairView):
    """JWT Login Endpoint"""
    serializer_class = CustomTokenObtainPairSerializer


class UserRegistrationView(generics.CreateAPIView):
    """User Self-Registration Endpoint"""
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny]


class CurrentUserView(generics.RetrieveUpdateAPIView):
    """Get / Update Logged In User Profile"""
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


# =============================================================================
# 2. USER & PROFILE VIEWSETS
# =============================================================================

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by('-created_at')
    serializer_class = UserSerializer
    permission_classes = [IsAdmin]


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all().select_related('user')
    permission_classes = [IsOwnerOrStaff]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return CustomerSerializer
        return CustomerWriteSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == User.Role.CUSTOMER:
            return Customer.objects.filter(user=user)
        return super().get_queryset()


class MechanicViewSet(viewsets.ModelViewSet):
    queryset = Mechanic.objects.all().select_related('user')
    permission_classes = [IsStaffUser]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return MechanicSerializer
        return MechanicWriteSerializer


# =============================================================================
# 3. VEHICLE VIEWSET
# =============================================================================

class VehicleViewSet(viewsets.ModelViewSet):
    queryset = Vehicle.objects.all().select_related('customer__user')
    permission_classes = [IsOwnerOrStaff]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return VehicleReadSerializer
        return VehicleWriteSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == User.Role.CUSTOMER:
            return Vehicle.objects.filter(customer__user=user)
        return super().get_queryset()


# =============================================================================
# 4. SERVICE & CATEGORY VIEWSETS
# =============================================================================

class ServiceCategoryViewSet(viewsets.ModelViewSet):
    queryset = ServiceCategory.objects.all()
    serializer_class = ServiceCategorySerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [IsAdminOrReceptionist()]


class ServiceViewSet(viewsets.ModelViewSet):
    queryset = Service.objects.all().select_related('category')

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return ServiceReadSerializer
        return ServiceWriteSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [IsAdminOrReceptionist()]


# =============================================================================
# 5. BOOKING VIEWSET (Slot Conflict Guardrails & Check-In Action)
# =============================================================================

class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all().select_related('vehicle__customer__user', 'service')
    permission_classes = [IsOwnerOrStaff]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return BookingReadSerializer
        return BookingWriteSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == User.Role.CUSTOMER:
            return Booking.objects.filter(vehicle__customer__user=user)
        return super().get_queryset()

    @action(detail=True, methods=['post'], permission_classes=[IsAdminOrReceptionist])
    def check_in(self, request, pk=None):
        """
        Workflow 3: Convert Booking to RepairJob during Customer Arrival Check-In.
        """
        booking = self.get_object()
        if booking.status in [Booking.BookingStatus.CANCELLED, Booking.BookingStatus.COMPLETED]:
            return Response({"error": f"Cannot check in booking with status '{booking.status}'."}, status=status.HTTP_400_BAD_REQUEST)

        check_in_mileage = request.data.get('check_in_mileage', booking.vehicle.mileage)
        fuel_level = request.data.get('fuel_level', 'HALF')
        vehicle_condition = request.data.get('vehicle_condition', '')
        mechanic_id = request.data.get('mechanic_id', None)

        mechanic = None
        if mechanic_id:
            try:
                mechanic = Mechanic.objects.get(pk=mechanic_id)
            except Mechanic.DoesNotExist:
                return Response({"error": "Selected mechanic does not exist."}, status=status.HTTP_400_BAD_REQUEST)

        # Update booking status
        booking.status = Booking.BookingStatus.CHECKED_IN
        booking.save(update_fields=['status'])

        # Update vehicle status
        booking.vehicle.status = Vehicle.VehicleStatus.IN_SERVICE
        booking.vehicle.save(update_fields=['status'])

        # Create RepairJob
        repair_job = RepairJob.objects.create(
            booking=booking,
            vehicle=booking.vehicle,
            mechanic=mechanic,
            check_in_mileage=check_in_mileage,
            fuel_level=fuel_level,
            vehicle_condition=vehicle_condition,
            status=RepairJob.RepairStatus.PENDING,
            assignment_status=RepairJob.AssignmentStatus.ASSIGNED if mechanic else RepairJob.AssignmentStatus.UNASSIGNED,
            assignment_date=timezone.now() if mechanic else None
        )

        return Response(RepairJobReadSerializer(repair_job).data, status=status.HTTP_201_CREATED)


# =============================================================================
# 6. REPAIR JOB VIEWSET (Mechanic Assignment & Completion)
# =============================================================================

class RepairJobViewSet(viewsets.ModelViewSet):
    queryset = RepairJob.objects.all().select_related('vehicle__customer__user', 'mechanic__user', 'booking')
    permission_classes = [IsStaffUser]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return RepairJobReadSerializer
        return RepairJobWriteSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == User.Role.MECHANIC and hasattr(user, 'mechanic_profile'):
            return RepairJob.objects.filter(mechanic=user.mechanic_profile)
        elif user.role == User.Role.CUSTOMER:
            return RepairJob.objects.filter(vehicle__customer__user=user)
        return super().get_queryset()

    @action(detail=True, methods=['post'], permission_classes=[IsAdminOrReceptionist])
    def assign_mechanic(self, request, pk=None):
        """Assign or reassign mechanic to repair job."""
        repair_job = self.get_object()
        mechanic_id = request.data.get('mechanic_id')
        if not mechanic_id:
            return Response({"error": "mechanic_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            mechanic = Mechanic.objects.get(pk=mechanic_id)
        except Mechanic.DoesNotExist:
            return Response({"error": "Mechanic not found."}, status=status.HTTP_404_NOT_FOUND)

        repair_job.mechanic = mechanic
        repair_job.assignment_status = RepairJob.AssignmentStatus.ASSIGNED
        repair_job.assignment_date = timezone.now()
        repair_job.save()

        # Update mechanic availability
        mechanic.availability_status = Mechanic.AvailabilityStatus.BUSY
        mechanic.save(update_fields=['availability_status'])

        return Response(RepairJobReadSerializer(repair_job).data)

    @action(detail=True, methods=['post'], permission_classes=[IsStaffUser])
    def complete_job(self, request, pk=None):
        """
        Mark RepairJob as COMPLETED (Triggers ServiceHistory creation via signal).
        """
        repair_job = self.get_object()
        repair_job.status = RepairJob.RepairStatus.COMPLETED
        repair_job.save()

        if repair_job.mechanic:
            repair_job.mechanic.availability_status = Mechanic.AvailabilityStatus.AVAILABLE
            repair_job.mechanic.save(update_fields=['availability_status'])

        return Response(RepairJobReadSerializer(repair_job).data)


# =============================================================================
# 7. DIAGNOSIS VIEWSET
# =============================================================================

class DiagnosisViewSet(viewsets.ModelViewSet):
    queryset = Diagnosis.objects.all().select_related('repair_job')
    serializer_class = DiagnosisSerializer
    permission_classes = [IsStaffUser]


# =============================================================================
# 8. SPARE PART & PART USAGE VIEWSETS
# =============================================================================

class SparePartViewSet(viewsets.ModelViewSet):
    queryset = SparePart.objects.all().order_by('part_name')
    serializer_class = SparePartSerializer
    permission_classes = [IsStaffUser]

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """List spare parts that are low on stock or out of stock."""
        qs = SparePart.objects.filter(stock_status__in=[SparePart.StockStatus.LOW_STOCK, SparePart.StockStatus.OUT_OF_STOCK])
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)


class PartUsageViewSet(viewsets.ModelViewSet):
    queryset = PartUsage.objects.all().select_related('repair_job', 'part')
    permission_classes = [IsStaffUser]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return PartUsageReadSerializer
        return PartUsageWriteSerializer


# =============================================================================
# 9. ESTIMATE & INVOICE VIEWSETS (Auto-Calculation Endpoints)
# =============================================================================

class EstimateViewSet(viewsets.ModelViewSet):
    queryset = Estimate.objects.all().select_related('repair_job')
    serializer_class = EstimateSerializer
    permission_classes = [IsOwnerOrStaff]

    @action(detail=True, methods=['post'], permission_classes=[IsOwnerOrStaff])
    def confirm(self, request, pk=None):
        """Customer confirms estimate."""
        estimate = self.get_object()
        estimate.customer_confirmed = True
        estimate.confirmed_at = timezone.now()
        estimate.save()
        return Response(EstimateSerializer(estimate).data)


class InvoiceViewSet(viewsets.ModelViewSet):
    queryset = Invoice.objects.all().select_related('repair_job')
    permission_classes = [IsOwnerOrStaff]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return InvoiceReadSerializer
        return InvoiceWriteSerializer

    @action(detail=True, methods=['post'], permission_classes=[IsAdminOrReceptionist])
    def calculate(self, request, pk=None):
        """
        Invoice Auto-Calculation Endpoint:
        Calculates subtotal and total_amount (Labor + Parts + Service Fee + Tax - Discount)
        """
        invoice = self.get_object()

        labor_cost = request.data.get('labor_cost', invoice.labor_cost)
        service_fee = request.data.get('service_fee', invoice.service_fee)
        parts_cost = request.data.get('parts_cost', invoice.parts_cost)
        discount = request.data.get('discount', invoice.discount)
        tax = request.data.get('tax', invoice.tax)

        invoice.labor_cost = Decimal(str(labor_cost))
        invoice.service_fee = Decimal(str(service_fee))
        invoice.parts_cost = Decimal(str(parts_cost))
        invoice.discount = Decimal(str(discount))
        invoice.tax = Decimal(str(tax))

        invoice.calculate_totals()
        invoice.save()

        return Response(InvoiceReadSerializer(invoice).data)

    @action(detail=False, methods=['post'], permission_classes=[IsAdminOrReceptionist])
    def generate_from_job(self, request):
        """
        Automatically aggregate PartUsage costs and service standard price into a new Invoice.
        """
        repair_job_id = request.data.get('repair_job_id')
        if not repair_job_id:
            return Response({"error": "repair_job_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            repair_job = RepairJob.objects.get(pk=repair_job_id)
        except RepairJob.DoesNotExist:
            return Response({"error": "RepairJob not found."}, status=status.HTTP_404_NOT_FOUND)

        # 1. Aggregate parts cost
        parts_cost = sum(usage.parts_cost for usage in repair_job.part_usages.all())

        # 2. Get service price if booking exists
        service_fee = repair_job.booking.service.standard_price if (repair_job.booking and repair_job.booking.service) else Decimal('0.00')

        labor_cost = Decimal(str(request.data.get('labor_cost', '50.00')))
        tax_rate = Decimal(str(request.data.get('tax_rate', '0.07')))
        discount = Decimal(str(request.data.get('discount', '0.00')))

        subtotal = labor_cost + service_fee + parts_cost
        tax = subtotal * tax_rate

        invoice, created = Invoice.objects.update_or_create(
            repair_job=repair_job,
            defaults={
                'labor_cost': labor_cost,
                'service_fee': service_fee,
                'parts_cost': parts_cost,
                'discount': discount,
                'tax': tax,
                'subtotal': subtotal,
                'total_amount': subtotal + tax - discount,
            }
        )

        return Response(InvoiceReadSerializer(invoice).data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

    @action(detail=True, methods=['get'], permission_classes=[IsOwnerOrStaff])
    def pdf(self, request, pk=None):
        """
        Generates and streams a printable ReportLab PDF invoice document.
        """
        invoice = self.get_object()
        pdf_bytes = generate_invoice_pdf(invoice)

        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        response['Content-Disposition'] = f'inline; filename="invoice_{invoice.id}.pdf"'
        return response


# =============================================================================
# 10. PAYMENT VIEWSET
# =============================================================================

class PaymentViewSet(viewsets.ModelViewSet):
    queryset = Payment.objects.all().select_related('invoice__repair_job')
    permission_classes = [IsAdminOrReceptionist]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return PaymentReadSerializer
        return PaymentWriteSerializer


# =============================================================================
# 11. SERVICE HISTORY & REMINDERS
# =============================================================================

class ServiceHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ServiceHistory.objects.all().select_related('vehicle__customer__user', 'mechanic__user')
    serializer_class = ServiceHistoryReadSerializer
    permission_classes = [IsOwnerOrStaff]

    def get_queryset(self):
        user = self.request.user
        if user.role == User.Role.CUSTOMER:
            return ServiceHistory.objects.filter(vehicle__customer__user=user)
        return super().get_queryset()


class MaintenanceReminderViewSet(viewsets.ModelViewSet):
    queryset = MaintenanceReminder.objects.all().select_related('vehicle__customer__user')
    permission_classes = [IsOwnerOrStaff]

    def get_serializer_class(self):
        if self.action in ['list', 'retrieve']:
            return MaintenanceReminderSerializer
        return MaintenanceReminderWriteSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == User.Role.CUSTOMER:
            return MaintenanceReminder.objects.filter(vehicle__customer__user=user)
        return super().get_queryset()


# =============================================================================
# 12. NOTIFICATION & ACTIVITY LOG VIEWSETS
# =============================================================================

class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({"status": "Notification marked as read."})


class ActivityLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ActivityLog.objects.all().order_by('-created_at')
    serializer_class = ActivityLogSerializer
    permission_classes = [IsAdmin]
