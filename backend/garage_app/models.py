from django.db import models
from django.contrib.auth.models import AbstractUser
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.core.exceptions import ValidationError
from decimal import Decimal

# -----------------------------------------------------------------------------
# 1. Custom User Model
# -----------------------------------------------------------------------------
class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = 'ADMIN', 'Admin'
        RECEPTIONIST = 'RECEPTIONIST', 'Receptionist'
        MECHANIC = 'MECHANIC', 'Mechanic'
        CUSTOMER = 'CUSTOMER', 'Customer'

    class AccountStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        INACTIVE = 'INACTIVE', 'Inactive'
        SUSPENDED = 'SUSPENDED', 'Suspended'

    full_name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.CUSTOMER)
    phone = models.CharField(max_length=20, blank=True, default='')
    profile_photo = models.ImageField(upload_to='profile_photos/', null=True, blank=True)
    account_status = models.CharField(max_length=20, choices=AccountStatus.choices, default=AccountStatus.ACTIVE)
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'full_name']

    def __str__(self):
        return f"{self.full_name} ({self.role})"


# -----------------------------------------------------------------------------
# 2. Customer Model
# -----------------------------------------------------------------------------
class Customer(models.Model):
    class Gender(models.TextChoices):
        MALE = 'MALE', 'Male'
        FEMALE = 'FEMALE', 'Female'
        OTHER = 'OTHER', 'Other'

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='customer_profile')
    gender = models.CharField(max_length=10, choices=Gender.choices, default=Gender.OTHER)
    address = models.TextField(blank=True, default='')

    def __str__(self):
        return f"Customer: {self.user.full_name}"


# -----------------------------------------------------------------------------
# 3. Vehicle Model
# -----------------------------------------------------------------------------
class Vehicle(models.Model):
    class VehicleStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        IN_SERVICE = 'IN_SERVICE', 'In Service'
        INACTIVE = 'INACTIVE', 'Inactive'

    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='vehicles')
    plate_number = models.CharField(max_length=20, unique=True)
    brand = models.CharField(max_length=50)
    model = models.CharField(max_length=50)
    year = models.IntegerField()
    color = models.CharField(max_length=30)
    vin = models.CharField(max_length=50, unique=True, null=True, blank=True)
    engine_number = models.CharField(max_length=50, null=True, blank=True)
    mileage = models.IntegerField(default=0)
    vehicle_photo = models.ImageField(upload_to='vehicle_photos/', null=True, blank=True)
    status = models.CharField(max_length=20, choices=VehicleStatus.choices, default=VehicleStatus.ACTIVE)

    def __str__(self):
        return f"{self.brand} {self.model} ({self.plate_number})"


# -----------------------------------------------------------------------------
# 4. ServiceCategory Model
# -----------------------------------------------------------------------------
class ServiceCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.name


# -----------------------------------------------------------------------------
# 5. Service Model
# -----------------------------------------------------------------------------
class Service(models.Model):
    class ServiceStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        INACTIVE = 'INACTIVE', 'Inactive'

    category = models.ForeignKey(ServiceCategory, on_delete=models.CASCADE, related_name='services')
    name = models.CharField(max_length=150)
    description = models.TextField(blank=True, default='')
    standard_price = models.DecimalField(max_digits=10, decimal_places=2)
    estimated_duration_min = models.IntegerField(default=60)
    status = models.CharField(max_length=20, choices=ServiceStatus.choices, default=ServiceStatus.ACTIVE)

    def __str__(self):
        return f"{self.name} (${self.standard_price})"


# -----------------------------------------------------------------------------
# 6. Mechanic Model
# -----------------------------------------------------------------------------
class Mechanic(models.Model):
    class AvailabilityStatus(models.TextChoices):
        AVAILABLE = 'AVAILABLE', 'Available'
        BUSY = 'BUSY', 'Busy'
        OFF_DUTY = 'OFF_DUTY', 'Off Duty'

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='mechanic_profile')
    skill = models.CharField(max_length=255, blank=True, default='')
    specialization = models.CharField(max_length=255, blank=True, default='')
    availability_status = models.CharField(max_length=20, choices=AvailabilityStatus.choices, default=AvailabilityStatus.AVAILABLE)

    def __str__(self):
        return f"Mechanic: {self.user.full_name}"


# -----------------------------------------------------------------------------
# 7. Booking Model
# -----------------------------------------------------------------------------
class Booking(models.Model):
    class BookingStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        CONFIRMED = 'CONFIRMED', 'Confirmed'
        CANCELLED = 'CANCELLED', 'Cancelled'
        CHECKED_IN = 'CHECKED_IN', 'Checked In'
        COMPLETED = 'COMPLETED', 'Completed'

    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='bookings')
    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name='bookings')
    booking_date = models.DateField()
    booking_time = models.TimeField()
    problem_description = models.TextField(blank=True, default='')
    note = models.TextField(blank=True, default='')
    status = models.CharField(max_length=20, choices=BookingStatus.choices, default=BookingStatus.PENDING)
    cancel_reason = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Booking #{self.id} - {self.vehicle} on {self.booking_date}"


# -----------------------------------------------------------------------------
# 8. RepairJob Model
# -----------------------------------------------------------------------------
class RepairJob(models.Model):
    class RepairStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
        WAITING_FOR_PARTS = 'WAITING_FOR_PARTS', 'Waiting for Parts'
        COMPLETED = 'COMPLETED', 'Completed'
        CANCELLED = 'CANCELLED', 'Cancelled'

    class FuelLevel(models.TextChoices):
        EMPTY = 'EMPTY', 'Empty'
        QUARTER = 'QUARTER', '1/4'
        HALF = 'HALF', '1/2'
        THREE_QUARTER = 'THREE_QUARTER', '3/4'
        FULL = 'FULL', 'Full'

    class AssignmentStatus(models.TextChoices):
        UNASSIGNED = 'UNASSIGNED', 'Unassigned'
        ASSIGNED = 'ASSIGNED', 'Assigned'
        IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
        REASSIGNED = 'REASSIGNED', 'Reassigned'

    booking = models.OneToOneField(Booking, on_delete=models.SET_NULL, null=True, blank=True, related_name='repair_job')
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='repair_jobs')
    mechanic = models.ForeignKey(Mechanic, on_delete=models.SET_NULL, null=True, blank=True, related_name='repair_jobs')
    check_in_date = models.DateTimeField(auto_now_add=True)
    check_in_mileage = models.IntegerField(default=0)
    fuel_level = models.CharField(max_length=20, choices=FuelLevel.choices, default=FuelLevel.HALF)
    vehicle_condition = models.TextField(blank=True, default='')
    status = models.CharField(max_length=20, choices=RepairStatus.choices, default=RepairStatus.PENDING)
    start_date = models.DateTimeField(null=True, blank=True)
    expected_completion_date = models.DateTimeField(null=True, blank=True)
    repair_note = models.TextField(blank=True, default='')
    assignment_date = models.DateTimeField(null=True, blank=True)
    assignment_status = models.CharField(max_length=20, choices=AssignmentStatus.choices, default=AssignmentStatus.UNASSIGNED)

    def __str__(self):
        return f"RepairJob #{self.id} - {self.vehicle.plate_number}"


# -----------------------------------------------------------------------------
# 9. Diagnosis Model
# -----------------------------------------------------------------------------
class Diagnosis(models.Model):
    repair_job = models.ForeignKey(RepairJob, on_delete=models.CASCADE, related_name='diagnoses')
    finding = models.TextField()
    recommended_action = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Diagnosis for Job #{self.repair_job_id}"


# -----------------------------------------------------------------------------
# 10. SparePart Model
# -----------------------------------------------------------------------------
class SparePart(models.Model):
    class StockStatus(models.TextChoices):
        IN_STOCK = 'IN_STOCK', 'In Stock'
        LOW_STOCK = 'LOW_STOCK', 'Low Stock'
        OUT_OF_STOCK = 'OUT_OF_STOCK', 'Out of Stock'

    part_number = models.CharField(max_length=50, unique=True)
    part_name = models.CharField(max_length=150)
    category = models.CharField(max_length=100)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.IntegerField(default=0)
    min_stock_qty = models.IntegerField(default=5)
    stock_status = models.CharField(max_length=20, choices=StockStatus.choices, default=StockStatus.IN_STOCK)

    def update_stock_status(self):
        if self.quantity <= 0:
            self.stock_status = self.StockStatus.OUT_OF_STOCK
        elif self.quantity <= self.min_stock_qty:
            self.stock_status = self.StockStatus.LOW_STOCK
        else:
            self.stock_status = self.StockStatus.IN_STOCK

    def save(self, *args, **kwargs):
        self.update_stock_status()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.part_name} ({self.part_number}) - Qty: {self.quantity}"


# -----------------------------------------------------------------------------
# 11. PartUsage Model
# -----------------------------------------------------------------------------
class PartUsage(models.Model):
    repair_job = models.ForeignKey(RepairJob, on_delete=models.CASCADE, related_name='part_usages')
    part = models.ForeignKey(SparePart, on_delete=models.CASCADE, related_name='part_usages')
    quantity_used = models.IntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    parts_cost = models.DecimalField(max_digits=10, decimal_places=2)

    def save(self, *args, **kwargs):
        if not self.unit_price:
            self.unit_price = self.part.unit_price
        self.parts_cost = Decimal(self.quantity_used) * Decimal(str(self.unit_price))
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.quantity_used}x {self.part.part_name} for Job #{self.repair_job_id}"


# -----------------------------------------------------------------------------
# 12. Estimate Model
# -----------------------------------------------------------------------------
class Estimate(models.Model):
    repair_job = models.OneToOneField(RepairJob, on_delete=models.CASCADE, related_name='estimate')
    estimated_labor_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    estimated_parts_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    estimated_service_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    estimated_completion_time = models.DateTimeField(null=True, blank=True)
    customer_confirmed = models.BooleanField(default=False)
    confirmed_at = models.DateTimeField(null=True, blank=True)

    @property
    def total_estimate(self):
        return self.estimated_labor_cost + self.estimated_parts_cost + self.estimated_service_cost

    def __str__(self):
        return f"Estimate for Job #{self.repair_job_id}"


# -----------------------------------------------------------------------------
# 13. Invoice Model
# -----------------------------------------------------------------------------
class Invoice(models.Model):
    repair_job = models.OneToOneField(RepairJob, on_delete=models.CASCADE, related_name='invoice')
    labor_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    service_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    parts_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tax = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)

    def calculate_totals(self):
        self.subtotal = self.labor_cost + self.service_fee + self.parts_cost
        self.total_amount = self.subtotal + self.tax - self.discount

    def save(self, *args, **kwargs):
        self.calculate_totals()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Invoice #{self.id} - Job #{self.repair_job_id} (${self.total_amount})"


# -----------------------------------------------------------------------------
# 14. Payment Model
# -----------------------------------------------------------------------------
class Payment(models.Model):
    class PaymentMethod(models.TextChoices):
        CASH = 'CASH', 'Cash'
        CARD = 'CARD', 'Card'
        QR = 'QR', 'QR Code / PromptPay'
        BANK_TRANSFER = 'BANK_TRANSFER', 'Bank Transfer'

    class PaymentStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        COMPLETED = 'COMPLETED', 'Completed'
        FAILED = 'FAILED', 'Failed'
        REFUNDED = 'REFUNDED', 'Refunded'

    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name='payments')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    method = models.CharField(max_length=20, choices=PaymentMethod.choices, default=PaymentMethod.CASH)
    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    paid_date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Payment #{self.id} - Invoice #{self.invoice_id} (${self.amount})"


# -----------------------------------------------------------------------------
# 15. ServiceHistory Model
# -----------------------------------------------------------------------------
class ServiceHistory(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='service_histories')
    repair_job = models.ForeignKey(RepairJob, on_delete=models.CASCADE, related_name='service_histories')
    service_date = models.DateTimeField()
    service_type = models.CharField(max_length=150)
    mileage = models.IntegerField()
    mechanic = models.ForeignKey(Mechanic, on_delete=models.SET_NULL, null=True, blank=True, related_name='service_histories')
    cost = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"History: {self.vehicle.plate_number} on {self.service_date.strftime('%Y-%m-%d')}"


# -----------------------------------------------------------------------------
# 16. MaintenanceReminder Model
# -----------------------------------------------------------------------------
class MaintenanceReminder(models.Model):
    class ReminderStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        SENT = 'SENT', 'Sent'
        COMPLETED = 'COMPLETED', 'Completed'
        EXPIRED = 'EXPIRED', 'Expired'

    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='maintenance_reminders')
    reminder_type = models.CharField(max_length=150)
    due_date = models.DateField(null=True, blank=True)
    due_mileage = models.IntegerField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=ReminderStatus.choices, default=ReminderStatus.PENDING)

    def __str__(self):
        return f"Reminder: {self.reminder_type} for {self.vehicle.plate_number}"


# -----------------------------------------------------------------------------
# 17. Notification & ActivityLog Models
# -----------------------------------------------------------------------------
class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.user.full_name}: {self.title}"


class ActivityLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='activity_logs')
    action = models.CharField(max_length=255)
    details = models.TextField(blank=True, default='')
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"[{self.created_at.strftime('%Y-%m-%d %H:%M')}] {self.action}"

