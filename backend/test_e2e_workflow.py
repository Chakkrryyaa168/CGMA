import os
import django
import time
from decimal import Decimal
from datetime import date, timedelta

# Configure Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient
from garage_app.models import (
    User, Customer, Vehicle, ServiceCategory, Service, Mechanic, Booking,
    RepairJob, SparePart, PartUsage, Invoice, Payment, ServiceHistory
)

def run_e2e_workflow_test():
    print("=================================================================")
    print("    STARTING END-TO-END (E2E) GARAGE WORKFLOW TEST")
    print("=================================================================")

    client = APIClient()
    unique_suffix = int(time.time())

    # -------------------------------------------------------------------------
    # STEP 1: AUTHENTICATION & LOGIN
    # -------------------------------------------------------------------------
    print("\n[STEP 1] Testing Admin / Staff JWT Login...")
    login_resp = client.post('/api/auth/login/', {
        'email': 'admin@garage.com',
        'password': 'admin123'
    })
    assert login_resp.status_code == 200, f"Login failed: {login_resp.data}"
    access_token = login_resp.data['access']
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
    print("  -> Login Successful! Token received.")

    # -------------------------------------------------------------------------
    # STEP 2: REGISTER CUSTOMER & VEHICLE
    # -------------------------------------------------------------------------
    print("\n[STEP 2] Registering New Customer & Vehicle...")
    cust_email = f"e2e_{unique_suffix}@example.com"
    reg_resp = client.post('/api/auth/register/', {
        'email': cust_email,
        'password': 'password123',
        'full_name': f'E2E Customer {unique_suffix}',
        'role': 'CUSTOMER',
        'phone': '+1-555-9999',
        'gender': 'MALE',
        'address': '999 Testing Blvd'
    })
    assert reg_resp.status_code == 201, f"Customer registration failed: {reg_resp.data}"
    customer_user_id = reg_resp.data['id']
    customer_profile = Customer.objects.get(user_id=customer_user_id)
    print(f"  -> Customer Registered! ID: {customer_profile.id} ({customer_profile.user.full_name})")

    plate = f"E2E-{unique_suffix % 10000:04d}"
    veh_resp = client.post('/api/vehicles/', {
        'customer': customer_profile.id,
        'plate_number': plate,
        'brand': 'Honda',
        'model': 'Accord',
        'year': 2023,
        'color': 'Blue',
        'vin': f'VIN{unique_suffix}',
        'mileage': 15000,
        'status': 'ACTIVE'
    })
    assert veh_resp.status_code == 201, f"Vehicle creation failed: {veh_resp.data}"
    vehicle_id = veh_resp.data['id']
    print(f"  -> Vehicle Registered! ID: {vehicle_id} (Plate: {plate})")

    # Get service offering ID
    service = Service.objects.first()
    assert service is not None, "No service offering found in DB!"
    print(f"  -> Selected Service: {service.name} (${service.standard_price})")

    # -------------------------------------------------------------------------
    # STEP 3: CREATE BOOKING
    # -------------------------------------------------------------------------
    print("\n[STEP 3] Creating Service Booking...")
    booking_date_str = (date.today() + timedelta(days=1)).strftime('%Y-%m-%d')
    booking_resp = client.post('/api/bookings/', {
        'vehicle': vehicle_id,
        'service': service.id,
        'booking_date': booking_date_str,
        'booking_time': '10:00:00',
        'problem_description': 'Annual inspection and oil service',
        'note': 'E2E test booking'
    })
    assert booking_resp.status_code == 201, f"Booking creation failed: {booking_resp.data}"
    booking_id = booking_resp.data['id']
    print(f"  -> Booking Created! ID: {booking_id} (Status: {booking_resp.data['status']})")

    # -------------------------------------------------------------------------
    # STEP 4: VEHICLE CHECK-IN & REPAIR JOB CREATION
    # -------------------------------------------------------------------------
    print("\n[STEP 4] Performing Arrival Check-In (Converting Booking to RepairJob)...")
    checkin_resp = client.post(f'/api/bookings/{booking_id}/check_in/', {
        'check_in_mileage': 15200,
        'fuel_level': 'FULL',
        'vehicle_condition': 'Excellent condition, no scratches'
    })
    assert checkin_resp.status_code == 201, f"Check-in failed: {checkin_resp.data}"
    repair_job_id = checkin_resp.data['id']
    print(f"  -> Check-In Successful! RepairJob Created ID: {repair_job_id}")

    # -------------------------------------------------------------------------
    # STEP 5: ASSIGN MECHANIC
    # -------------------------------------------------------------------------
    print("\n[STEP 5] Assigning Mechanic to Repair Job...")
    mechanic = Mechanic.objects.first()
    assert mechanic is not None, "No mechanic found in DB!"
    assign_resp = client.post(f'/api/repair-jobs/{repair_job_id}/assign_mechanic/', {
        'mechanic_id': mechanic.id
    })
    assert assign_resp.status_code == 200, f"Mechanic assignment failed: {assign_resp.data}"
    print(f"  -> Mechanic Assigned! ({mechanic.user.full_name}, Status: ASSIGNED)")

    # Log Diagnosis
    diag_resp = client.post('/api/diagnoses/', {
        'repair_job': repair_job_id,
        'finding': 'Engine oil dark, filter clean.',
        'recommended_action': 'Drain oil and replace with synthetic 5W-30.'
    })
    assert diag_resp.status_code == 201
    print("  -> Diagnosis Logged.")

    # -------------------------------------------------------------------------
    # STEP 6: LOG SPARE PART USAGE & AUTO-DEDUCT STOCK
    # -------------------------------------------------------------------------
    print("\n[STEP 6] Logging Spare Part Usage & Testing Stock Auto-Deduction Signal...")
    spare_part = SparePart.objects.first()
    initial_qty = spare_part.quantity
    qty_to_use = 2

    part_usage_resp = client.post('/api/part-usages/', {
        'repair_job': repair_job_id,
        'part': spare_part.id,
        'quantity_used': qty_to_use
    })
    assert part_usage_resp.status_code == 201, f"Part usage failed: {part_usage_resp.data}"

    spare_part.refresh_from_db()
    expected_qty = initial_qty - qty_to_use
    assert spare_part.quantity == expected_qty, f"Stock deduction signal failed! Expected {expected_qty}, got {spare_part.quantity}"
    print(f"  -> Spare Part Used: {spare_part.part_name} (Qty: {qty_to_use})")
    print(f"  -> Signal Verified: Stock auto-deducted from {initial_qty} to {spare_part.quantity}!")

    # -------------------------------------------------------------------------
    # STEP 7: COMPLETE REPAIR JOB
    # -------------------------------------------------------------------------
    print("\n[STEP 7] Completing Repair Job...")
    complete_resp = client.post(f'/api/repair-jobs/{repair_job_id}/complete_job/')
    assert complete_resp.status_code == 200, f"Job completion failed: {complete_resp.data}"
    print(f"  -> Repair Job Status: {complete_resp.data['status']}")

    # -------------------------------------------------------------------------
    # STEP 8: GENERATE INVOICE
    # -------------------------------------------------------------------------
    print("\n[STEP 8] Generating Itemized Invoice...")
    inv_gen_resp = client.post('/api/invoices/generate_from_job/', {
        'repair_job_id': repair_job_id,
        'labor_cost': '50.00',
        'tax_rate': '0.07',
        'discount': '0.00'
    })
    assert inv_gen_resp.status_code in [200, 201], f"Invoice generation failed: {inv_gen_resp.data}"
    invoice_id = inv_gen_resp.data['id']
    total_amount = inv_gen_resp.data['total_amount']
    print(f"  -> Invoice Generated! ID: {invoice_id} | Total Amount: ${total_amount}")

    # -------------------------------------------------------------------------
    # STEP 9: PROCESS PAYMENT & TRIGGER COMPLETION SIGNALS
    # -------------------------------------------------------------------------
    print("\n[STEP 9] Processing Payment (Completing Invoice)...")
    pay_resp = client.post('/api/payments/', {
        'invoice': invoice_id,
        'amount': total_amount,
        'method': 'CASH',
        'status': 'COMPLETED'
    })
    assert pay_resp.status_code == 201, f"Payment failed: {pay_resp.data}"
    print(f"  -> Payment Completed! Status: {pay_resp.data['status']}")

    # -------------------------------------------------------------------------
    # STEP 10: VERIFY SERVICE HISTORY & VEHICLE MILEAGE UPDATE
    # -------------------------------------------------------------------------
    print("\n[STEP 10] Verifying Automated ServiceHistory Entry & Vehicle Mileage Update...")
    history_resp = client.get('/api/service-history/')
    assert history_resp.status_code == 200
    histories = [h for h in history_resp.data if h['repair_job'] == repair_job_id]
    assert len(histories) > 0, "ServiceHistory auto-creation signal failed! No entry found for repair job."

    matched_history = histories[0]
    print(f"  -> ServiceHistory Entry Verified!")
    print(f"     Date: {matched_history['service_date']}")
    print(f"     Mileage logged: {matched_history['mileage']} km")
    print(f"     Total Cost recorded: ${matched_history['cost']}")

    vehicle_obj = Vehicle.objects.get(pk=vehicle_id)
    assert vehicle_obj.mileage == 15200, f"Vehicle mileage update failed! Expected 15200, got {vehicle_obj.mileage}"
    assert vehicle_obj.status == Vehicle.VehicleStatus.ACTIVE, f"Vehicle status update failed! Expected ACTIVE, got {vehicle_obj.status}"
    print(f"  -> Vehicle Status Verified: {vehicle_obj.status} (Mileage updated to {vehicle_obj.mileage} km)")

    print("\n=================================================================")
    print("    ALL 10 END-TO-END WORKFLOW STEPS PASSED SUCCESSFULLY!")
    print("=================================================================\n")

if __name__ == '__main__':
    run_e2e_workflow_test()
