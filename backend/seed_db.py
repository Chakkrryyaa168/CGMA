import os
import django
from decimal import Decimal
from datetime import date, time, timedelta
from django.utils import timezone

# Configure Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from garage_app.models import (
    User, Customer, Vehicle, ServiceCategory, Service, Mechanic, Booking,
    RepairJob, Diagnosis, SparePart, PartUsage, Estimate, Invoice, Payment,
    ServiceHistory, MaintenanceReminder, Notification, ActivityLog
)

def seed_database():
    print("Starting database seeding process...")

    # Clear existing data safely
    print("Clearing old data...")
    ActivityLog.objects.all().delete()
    Notification.objects.all().delete()
    MaintenanceReminder.objects.all().delete()
    ServiceHistory.objects.all().delete()
    Payment.objects.all().delete()
    Invoice.objects.all().delete()
    Estimate.objects.all().delete()
    PartUsage.objects.all().delete()
    Diagnosis.objects.all().delete()
    RepairJob.objects.all().delete()
    Booking.objects.all().delete()
    SparePart.objects.all().delete()
    Service.objects.all().delete()
    ServiceCategory.objects.all().delete()
    Vehicle.objects.all().delete()
    Mechanic.objects.all().delete()
    Customer.objects.all().delete()
    User.objects.all().delete()

    print("Creating Users...")
    # 1. Admin Account
    admin_user = User.objects.create_superuser(
        username='admin@garage.com',
        email='admin@garage.com',
        password='admin123',
        full_name='System Admin Manager',
        role=User.Role.ADMIN,
        phone='+1-555-0100'
    )
    print(f"Created Admin: {admin_user.email} (password: admin123)")

    # 1b. Receptionist Account
    receptionist_user = User.objects.create_user(
        username='receptionist@garage.com',
        email='receptionist@garage.com',
        password='rec123',
        full_name='Sarah Jenkins (Receptionist)',
        role=User.Role.RECEPTIONIST,
        phone='+1-555-0101'
    )
    print(f"Created Receptionist: {receptionist_user.email} (password: rec123)")

    # 2 Mechanics
    mech1_user = User.objects.create_user(
        username='mechanic1@garage.com',
        email='mechanic1@garage.com',
        password='mech123',
        full_name='John Doe (Mechanic)',
        role=User.Role.MECHANIC,
        phone='+1-555-0102'
    )
    mech1 = Mechanic.objects.create(
        user=mech1_user,
        skill='Engine Diagnostics & Tuning',
        specialization='European Cars (BMW, Audi, Mercedes)',
        availability_status=Mechanic.AvailabilityStatus.AVAILABLE
    )

    mech2_user = User.objects.create_user(
        username='mechanic2@garage.com',
        email='mechanic2@garage.com',
        password='mech123',
        full_name='Alex Smith (Mechanic)',
        role=User.Role.MECHANIC,
        phone='+1-555-0103'
    )
    mech2 = Mechanic.objects.create(
        user=mech2_user,
        skill='Brakes, Suspension & Transmission',
        specialization='Japanese & Asian Cars (Toyota, Honda, Nissan)',
        availability_status=Mechanic.AvailabilityStatus.BUSY
    )
    print("Created 2 Mechanics (John Doe, Alex Smith)")

    # 3 Customers
    cust1_user = User.objects.create_user(
        username='customer1@example.com',
        email='customer1@example.com',
        password='cust123',
        full_name='Alice Johnson',
        role=User.Role.CUSTOMER,
        phone='+1-555-0201'
    )
    cust1 = Customer.objects.create(user=cust1_user, gender=Customer.Gender.FEMALE, address='123 Main Street, Suite 4B')

    cust2_user = User.objects.create_user(
        username='customer2@example.com',
        email='customer2@example.com',
        password='cust123',
        full_name='Bob Williams',
        role=User.Role.CUSTOMER,
        phone='+1-555-0202'
    )
    cust2 = Customer.objects.create(user=cust2_user, gender=Customer.Gender.MALE, address='456 Oak Avenue, Apt 12')

    cust3_user = User.objects.create_user(
        username='customer3@example.com',
        email='customer3@example.com',
        password='cust123',
        full_name='Charlie Brown',
        role=User.Role.CUSTOMER,
        phone='+1-555-0203'
    )
    cust3 = Customer.objects.create(user=cust3_user, gender=Customer.Gender.MALE, address='789 Pine Road')
    print("Created 3 Customers (Alice, Bob, Charlie)")

    print("Creating Vehicles...")
    # 3 Vehicles
    v1 = Vehicle.objects.create(
        customer=cust1,
        plate_number='ABC-1234',
        brand='Toyota',
        model='Camry',
        year=2020,
        color='Silver',
        vin='1NXBR3ABE5Z123456',
        engine_number='ENG-TOY-8849',
        mileage=45000,
        status=Vehicle.VehicleStatus.ACTIVE
    )

    v2 = Vehicle.objects.create(
        customer=cust2,
        plate_number='XYZ-9876',
        brand='Honda',
        model='Civic',
        year=2021,
        color='Black',
        vin='2HGFC2F53MH987654',
        engine_number='ENG-HON-5521',
        mileage=32000,
        status=Vehicle.VehicleStatus.IN_SERVICE
    )

    v3 = Vehicle.objects.create(
        customer=cust3,
        plate_number='BKK-5555',
        brand='BMW',
        model='330i',
        year=2022,
        color='White',
        vin='WBA33AY08NFP55555',
        engine_number='ENG-BMW-9912',
        mileage=18000,
        status=Vehicle.VehicleStatus.ACTIVE
    )
    print("Created 3 Vehicles (Toyota Camry, Honda Civic, BMW 330i)")

    print("Creating Service Categories & Services...")
    cat_routine = ServiceCategory.objects.create(name='Routine Maintenance')
    cat_brake = ServiceCategory.objects.create(name='Brake System')
    cat_engine = ServiceCategory.objects.create(name='Engine & Transmission')
    cat_wheels = ServiceCategory.objects.create(name='Tires & Suspension')

    s1 = Service.objects.create(
        category=cat_routine,
        name='Synthetic Oil Change & Filter Replacement',
        description='Full synthetic motor oil change with new OEM oil filter & multi-point inspection',
        standard_price=Decimal('65.00'),
        estimated_duration_min=45
    )

    s2 = Service.objects.create(
        category=cat_brake,
        name='Front Brake Inspection & Pad Replacement',
        description='Inspection of rotors, replacement of front ceramic brake pads & fluid top-up',
        standard_price=Decimal('150.00'),
        estimated_duration_min=90
    )

    s3 = Service.objects.create(
        category=cat_engine,
        name='Full Engine Computer Diagnostics',
        description='OBD-II computer scan, check engine light diagnosis, sensor telemetry check',
        standard_price=Decimal('90.00'),
        estimated_duration_min=60
    )

    s4 = Service.objects.create(
        category=cat_wheels,
        name='4-Wheel Alignment & Balancing',
        description='Computerized 4-wheel alignment and tire dynamic balancing',
        standard_price=Decimal('80.00'),
        estimated_duration_min=60
    )
    print("Created 4 Services across 4 categories")

    print("Creating Spare Parts...")
    part1 = SparePart.objects.create(
        part_number='SP-OIL-01',
        part_name='Synthetic Engine Oil 5W-30 (1L)',
        category='Fluids & Oils',
        unit_price=Decimal('35.00'),
        quantity=50,
        min_stock_qty=10
    )

    part2 = SparePart.objects.create(
        part_number='SP-FLTR-02',
        part_name='OEM Premium Oil Filter',
        category='Filters',
        unit_price=Decimal('15.00'),
        quantity=30,
        min_stock_qty=5
    )

    part3 = SparePart.objects.create(
        part_number='SP-BRK-03',
        part_name='Ceramic Front Brake Pads Set',
        category='Brakes',
        unit_price=Decimal('85.00'),
        quantity=12,
        min_stock_qty=4
    )

    part4 = SparePart.objects.create(
        part_number='SP-SPK-04',
        part_name='Iridium Spark Plugs Pack (4pcs)',
        category='Engine',
        unit_price=Decimal('45.00'),
        quantity=3, # Low stock!
        min_stock_qty=5
    )

    part5 = SparePart.objects.create(
        part_number='SP-BAT-05',
        part_name='Heavy Duty 12V 70Ah Battery',
        category='Electrical',
        unit_price=Decimal('120.00'),
        quantity=8,
        min_stock_qty=2
    )
    print("Created 5 Spare Parts (with SP-SPK-04 on Low Stock)")

    print("Creating Bookings & Repair Jobs...")
    # Booking 1: Completed Repair Job for Customer 1 (Toyota)
    b1 = Booking.objects.create(
        vehicle=v1,
        service=s1,
        booking_date=date.today() - timedelta(days=5),
        booking_time=time(9, 0),
        problem_description='Scheduled oil change service',
        status=Booking.BookingStatus.COMPLETED
    )

    rj1 = RepairJob.objects.create(
        booking=b1,
        vehicle=v1,
        mechanic=mech1,
        check_in_mileage=44800,
        fuel_level='FULL',
        vehicle_condition='Clean condition, minor scratch on front bumper',
        status=RepairJob.RepairStatus.COMPLETED,
        start_date=timezone.now() - timedelta(days=5),
        expected_completion_date=timezone.now() - timedelta(days=5),
        repair_note='Oil change performed smoothly. All fluids topped off.',
        assignment_status=RepairJob.AssignmentStatus.ASSIGNED
    )

    Diagnosis.objects.create(
        repair_job=rj1,
        finding='Engine oil dirty, oil filter degraded.',
        recommended_action='Replace engine oil and filter.'
    )

    # Use PartUsage
    PartUsage.objects.create(repair_job=rj1, part=part1, quantity_used=1, unit_price=part1.unit_price)
    PartUsage.objects.create(repair_job=rj1, part=part2, quantity_used=1, unit_price=part2.unit_price)

    # Create Invoice and Payment
    inv1 = Invoice.objects.create(
        repair_job=rj1,
        labor_cost=Decimal('30.00'),
        service_fee=Decimal('65.00'),
        parts_cost=Decimal('50.00'),
        discount=Decimal('5.00'),
        tax=Decimal('9.80'),
        subtotal=Decimal('145.00'),
        total_amount=Decimal('149.80')
    )

    Payment.objects.create(
        invoice=inv1,
        amount=inv1.total_amount,
        method=Payment.PaymentMethod.CREDIT_CARD if hasattr(Payment.PaymentMethod, 'CREDIT_CARD') else Payment.PaymentMethod.CARD,
        status=Payment.PaymentStatus.COMPLETED
    )

    # Booking 2: Active In-Progress Repair Job for Customer 2 (Honda Civic)
    b2 = Booking.objects.create(
        vehicle=v2,
        service=s2,
        booking_date=date.today(),
        booking_time=time(10, 30),
        problem_description='Squeaking noise when braking at low speed',
        status=Booking.BookingStatus.CHECKED_IN
    )

    rj2 = RepairJob.objects.create(
        booking=b2,
        vehicle=v2,
        mechanic=mech2,
        check_in_mileage=32000,
        fuel_level='HALF',
        vehicle_condition='Good overall condition',
        status=RepairJob.RepairStatus.IN_PROGRESS,
        start_date=timezone.now(),
        repair_note='Replacing front brake pads.',
        assignment_status=RepairJob.AssignmentStatus.ASSIGNED
    )

    Diagnosis.objects.create(
        repair_job=rj2,
        finding='Front brake pads worn down to 2mm.',
        recommended_action='Replace front ceramic brake pads and inspect rotors.'
    )

    PartUsage.objects.create(repair_job=rj2, part=part3, quantity_used=1, unit_price=part3.unit_price)

    Estimate.objects.create(
        repair_job=rj2,
        estimated_labor_cost=Decimal('60.00'),
        estimated_parts_cost=Decimal('85.00'),
        estimated_service_cost=Decimal('150.00'),
        estimated_completion_time=timezone.now() + timedelta(hours=3),
        customer_confirmed=True,
        confirmed_at=timezone.now()
    )

    # Booking 3: Upcoming Pending Booking for Customer 3 (BMW 330i)
    Booking.objects.create(
        vehicle=v3,
        service=s3,
        booking_date=date.today() + timedelta(days=2),
        booking_time=time(14, 0),
        problem_description='Check engine light came on yesterday',
        status=Booking.BookingStatus.PENDING
    )

    print("Created Bookings, Repair Jobs, Diagnoses, Estimates, Invoices, and Payments!")

    # Maintenance Reminder for Vehicle 3
    MaintenanceReminder.objects.create(
        vehicle=v3,
        reminder_type='6-Month Routine Inspection',
        due_date=date.today() + timedelta(days=30),
        due_mileage=20000,
        status=MaintenanceReminder.ReminderStatus.PENDING
    )

    print("\n=======================================================")
    print("Database seeding completed successfully!")
    print("=======================================================")
    print("DEMO LOGIN CREDENTIALS:")
    print("1. ADMIN:        email: admin@garage.com        / pass: admin123")
    print("2. RECEPTIONIST: email: receptionist@garage.com / pass: rec123")
    print("3. MECHANIC 1:   email: mechanic1@garage.com   / pass: mech123")
    print("4. MECHANIC 2:   email: mechanic2@garage.com   / pass: mech123")
    print("5. CUSTOMER 1:   email: customer1@example.com  / pass: cust123")
    print("6. CUSTOMER 2:   email: customer2@example.com  / pass: cust123")
    print("7. CUSTOMER 3:   email: customer3@example.com  / pass: cust123")
    print("=======================================================\n")

if __name__ == '__main__':
    seed_database()
