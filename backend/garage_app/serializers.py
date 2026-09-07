from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from decimal import Decimal
from .models import (
    User, Customer, Vehicle, ServiceCategory, Service, Mechanic, Booking,
    RepairJob, Diagnosis, SparePart, PartUsage, Estimate, Invoice, Payment,
    ServiceHistory, MaintenanceReminder, Notification, ActivityLog
)

User = get_user_model()

# =============================================================================
# 1. USER & AUTHENTICATION SERIALIZERS
# =============================================================================

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'full_name', 'role', 'phone', 'profile_photo', 'account_status', 'created_at']
        read_only_fields = ['id', 'created_at']


class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    gender = serializers.CharField(write_only=True, required=False, default='OTHER')
    address = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    skill = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    specialization = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')

    class Meta:
        model = User
        fields = ['id', 'email', 'password', 'full_name', 'role', 'phone', 'profile_photo', 'gender', 'address', 'skill', 'specialization']

    def create(self, validated_data):
        password = validated_data.pop('password')
        gender = validated_data.pop('gender', 'OTHER')
        address = validated_data.pop('address', '')
        skill = validated_data.pop('skill', '')
        specialization = validated_data.pop('specialization', '')
        
        email = validated_data.get('email')
        validated_data['username'] = email

        user = User.objects.create(**validated_data)
        user.set_password(password)
        user.save()

        # Automatically create profile based on Role
        if user.role == User.Role.CUSTOMER:
            Customer.objects.create(user=user, gender=gender, address=address)
        elif user.role == User.Role.MECHANIC:
            Mechanic.objects.create(user=user, skill=skill, specialization=specialization)

        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        # Add custom claims to response
        data['user'] = UserSerializer(self.user).data
        
        # Attach customer or mechanic ID if applicable
        if hasattr(self.user, 'customer_profile'):
            data['customer_id'] = self.user.customer_profile.id
        if hasattr(self.user, 'mechanic_profile'):
            data['mechanic_id'] = self.user.mechanic_profile.id
            
        return data


# =============================================================================
# 2. CUSTOMER & MECHANIC SERIALIZERS
# =============================================================================

class CustomerSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Customer
        fields = ['id', 'user', 'gender', 'address']


class CustomerWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = ['id', 'user', 'gender', 'address']


class MechanicSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Mechanic
        fields = ['id', 'user', 'skill', 'specialization', 'availability_status']


class MechanicWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mechanic
        fields = ['id', 'user', 'skill', 'specialization', 'availability_status']


# =============================================================================
# 3. VEHICLE SERIALIZERS
# =============================================================================

class VehicleReadSerializer(serializers.ModelSerializer):
    customer = CustomerSerializer(read_only=True)

    class Meta:
        model = Vehicle
        fields = [
            'id', 'customer', 'plate_number', 'brand', 'model', 'year',
            'color', 'vin', 'engine_number', 'mileage', 'vehicle_photo', 'status'
        ]


class VehicleWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = [
            'id', 'customer', 'plate_number', 'brand', 'model', 'year',
            'color', 'vin', 'engine_number', 'mileage', 'vehicle_photo', 'status'
        ]


# =============================================================================
# 4. SERVICE CATEGORY & SERVICE SERIALIZERS
# =============================================================================

class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ['id', 'name']


class ServiceReadSerializer(serializers.ModelSerializer):
    category = ServiceCategorySerializer(read_only=True)

    class Meta:
        model = Service
        fields = ['id', 'category', 'name', 'description', 'standard_price', 'estimated_duration_min', 'status']


class ServiceWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = ['id', 'category', 'name', 'description', 'standard_price', 'estimated_duration_min', 'status']


# =============================================================================
# 5. BOOKING SERIALIZERS
# =============================================================================

class BookingReadSerializer(serializers.ModelSerializer):
    vehicle = VehicleReadSerializer(read_only=True)
    service = ServiceReadSerializer(read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'vehicle', 'service', 'booking_date', 'booking_time',
            'problem_description', 'note', 'status', 'cancel_reason', 'created_at'
        ]


class BookingWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = [
            'id', 'vehicle', 'service', 'booking_date', 'booking_time',
            'problem_description', 'note', 'status', 'cancel_reason'
        ]

    def validate(self, attrs):
        booking_date = attrs.get('booking_date')
        booking_time = attrs.get('booking_time')
        vehicle = attrs.get('vehicle')

        # Check for existing booking for the same vehicle at the same date/time
        if vehicle and booking_date and booking_time:
            qs = Booking.objects.filter(
                vehicle=vehicle,
                booking_date=booking_date,
                booking_time=booking_time
            ).exclude(status=Booking.BookingStatus.CANCELLED)

            if self.instance:
                qs = qs.exclude(pk=self.instance.pk)

            if qs.exists():
                raise serializers.ValidationError("A booking for this vehicle already exists at the specified date and time.")

        return attrs


# =============================================================================
# 6. DIAGNOSIS SERIALIZER
# =============================================================================

class DiagnosisSerializer(serializers.ModelSerializer):
    class Meta:
        model = Diagnosis
        fields = ['id', 'repair_job', 'finding', 'recommended_action', 'created_at']
        read_only_fields = ['id', 'created_at']


# =============================================================================
# 7. SPARE PART SERIALIZERS
# =============================================================================

class SparePartSerializer(serializers.ModelSerializer):
    class Meta:
        model = SparePart
        fields = ['id', 'part_number', 'part_name', 'category', 'unit_price', 'quantity', 'min_stock_qty', 'stock_status']
        read_only_fields = ['id', 'stock_status']


# =============================================================================
# 8. PART USAGE SERIALIZERS
# =============================================================================

class PartUsageReadSerializer(serializers.ModelSerializer):
    part = SparePartSerializer(read_only=True)

    class Meta:
        model = PartUsage
        fields = ['id', 'repair_job', 'part', 'quantity_used', 'unit_price', 'parts_cost']


class PartUsageWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = PartUsage
        fields = ['id', 'repair_job', 'part', 'quantity_used', 'unit_price', 'parts_cost']
        read_only_fields = ['id', 'unit_price', 'parts_cost']

    def validate(self, attrs):
        part = attrs.get('part')
        quantity_used = attrs.get('quantity_used', 1)

        if part and part.quantity < quantity_used:
            raise serializers.ValidationError({
                "quantity_used": f"Insufficient stock! Available: {part.quantity}, requested: {quantity_used}."
            })

        return attrs


# =============================================================================
# 9. ESTIMATE SERIALIZERS
# =============================================================================

class EstimateSerializer(serializers.ModelSerializer):
    total_estimate = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Estimate
        fields = [
            'id', 'repair_job', 'estimated_labor_cost', 'estimated_parts_cost',
            'estimated_service_cost', 'estimated_completion_time', 'customer_confirmed',
            'confirmed_at', 'total_estimate'
        ]
        read_only_fields = ['id', 'total_estimate']


# =============================================================================
# 10. INVOICE SERIALIZERS
# =============================================================================

class InvoiceReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = [
            'id', 'repair_job', 'labor_cost', 'service_fee', 'parts_cost',
            'discount', 'tax', 'subtotal', 'total_amount', 'created_at'
        ]


class InvoiceWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = [
            'id', 'repair_job', 'labor_cost', 'service_fee', 'parts_cost',
            'discount', 'tax', 'subtotal', 'total_amount'
        ]
        read_only_fields = ['id', 'subtotal', 'total_amount']


# =============================================================================
# 11. PAYMENT SERIALIZERS
# =============================================================================

class PaymentReadSerializer(serializers.ModelSerializer):
    invoice = InvoiceReadSerializer(read_only=True)

    class Meta:
        model = Payment
        fields = ['id', 'invoice', 'amount', 'method', 'status', 'paid_date']


class PaymentWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ['id', 'invoice', 'amount', 'method', 'status', 'paid_date']
        read_only_fields = ['id', 'paid_date']


# =============================================================================
# 12. REPAIR JOB SERIALIZERS
# =============================================================================

class RepairJobReadSerializer(serializers.ModelSerializer):
    vehicle = VehicleReadSerializer(read_only=True)
    mechanic = MechanicSerializer(read_only=True)
    booking = BookingReadSerializer(read_only=True)
    diagnoses = DiagnosisSerializer(many=True, read_only=True)
    part_usages = PartUsageReadSerializer(many=True, read_only=True)
    estimate = EstimateSerializer(read_only=True)
    invoice = InvoiceReadSerializer(read_only=True)

    class Meta:
        model = RepairJob
        fields = [
            'id', 'booking', 'vehicle', 'mechanic', 'check_in_date',
            'check_in_mileage', 'fuel_level', 'vehicle_condition', 'status',
            'start_date', 'expected_completion_date', 'repair_note',
            'assignment_date', 'assignment_status',
            'diagnoses', 'part_usages', 'estimate', 'invoice'
        ]


class RepairJobWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = RepairJob
        fields = [
            'id', 'booking', 'vehicle', 'mechanic', 'check_in_mileage',
            'fuel_level', 'vehicle_condition', 'status', 'start_date',
            'expected_completion_date', 'repair_note', 'assignment_date',
            'assignment_status'
        ]


# =============================================================================
# 13. SERVICE HISTORY, MAINTENANCE REMINDER, NOTIFICATION & ACTIVITY LOG SERIALIZERS
# =============================================================================

class ServiceHistoryReadSerializer(serializers.ModelSerializer):
    vehicle = VehicleReadSerializer(read_only=True)
    mechanic = MechanicSerializer(read_only=True)

    class Meta:
        model = ServiceHistory
        fields = ['id', 'vehicle', 'repair_job', 'service_date', 'service_type', 'mileage', 'mechanic', 'cost']


class ServiceHistoryWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceHistory
        fields = ['id', 'vehicle', 'repair_job', 'service_date', 'service_type', 'mileage', 'mechanic', 'cost']


class MaintenanceReminderSerializer(serializers.ModelSerializer):
    vehicle = VehicleReadSerializer(read_only=True)

    class Meta:
        model = MaintenanceReminder
        fields = ['id', 'vehicle', 'reminder_type', 'due_date', 'due_mileage', 'status']


class MaintenanceReminderWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaintenanceReminder
        fields = ['id', 'vehicle', 'reminder_type', 'due_date', 'due_mileage', 'status']


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'user', 'title', 'message', 'is_read', 'created_at']
        read_only_fields = ['id', 'created_at']


class ActivityLogSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = ActivityLog
        fields = ['id', 'user', 'action', 'details', 'ip_address', 'created_at']
        read_only_fields = ['id', 'created_at']
