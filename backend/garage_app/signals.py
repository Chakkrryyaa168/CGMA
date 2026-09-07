from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils import timezone
from .models import (
    User, PartUsage, SparePart, RepairJob, Vehicle, Booking,
    Invoice, Payment, ServiceHistory, Notification, ActivityLog
)

@receiver(post_save, sender=PartUsage)
def auto_deduct_spare_part_stock(sender, instance, created, **kwargs):
    """
    1. Automatically deduct quantity_used from SparePart.quantity.
    2. Recalculate stock_status (IN_STOCK, LOW_STOCK, OUT_OF_STOCK).
    3. Send notification to Admins and Receptionists if stock is low or out of stock.
    """
    if created:
        part = instance.part
        part.quantity -= instance.quantity_used
        part.update_stock_status()
        part.save()

        # Send alert notification if LOW_STOCK or OUT_OF_STOCK
        if part.stock_status in [SparePart.StockStatus.LOW_STOCK, SparePart.StockStatus.OUT_OF_STOCK]:
            staff_users = User.objects.filter(role__in=[User.Role.ADMIN, User.Role.RECEPTIONIST])
            alert_msg = f"Part '{part.part_name}' ({part.part_number}) status is now {part.get_stock_status_display()}. Remaining quantity: {part.quantity}."
            for user in staff_users:
                Notification.objects.create(
                    user=user,
                    title="Low Stock Alert",
                    message=alert_msg
                )


@receiver(pre_save, sender=RepairJob)
def track_repair_job_previous_status(sender, instance, **kwargs):
    """
    Store previous status on the instance to detect status transition to 'COMPLETED'.
    """
    if instance.pk:
        try:
            old_instance = RepairJob.objects.get(pk=instance.pk)
            instance._previous_status = old_instance.status
        except RepairJob.DoesNotExist:
            instance._previous_status = None
    else:
        instance._previous_status = None


@receiver(post_save, sender=RepairJob)
def auto_create_service_history_on_repair_job_completed(sender, instance, created, **kwargs):
    """
    When RepairJob status transitions to 'COMPLETED', automatically:
    1. Create an entry in ServiceHistory.
    2. Update Vehicle status to 'ACTIVE' and mileage to check_in_mileage.
    3. Update related Booking status to 'COMPLETED' if exists.
    4. Notify the customer.
    """
    previous_status = getattr(instance, '_previous_status', None)

    if instance.status == RepairJob.RepairStatus.COMPLETED and previous_status != RepairJob.RepairStatus.COMPLETED:
        vehicle = instance.vehicle

        # 1. Update vehicle status and mileage
        vehicle.status = Vehicle.VehicleStatus.ACTIVE
        if instance.check_in_mileage > vehicle.mileage:
            vehicle.mileage = instance.check_in_mileage
        vehicle.save(update_fields=['status', 'mileage'])

        # 2. Update booking status if linked
        if instance.booking:
            instance.booking.status = Booking.BookingStatus.COMPLETED
            instance.booking.save(update_fields=['status'])

        # 3. Calculate total cost from Invoice if available, else 0
        total_cost = 0.00
        if hasattr(instance, 'invoice') and instance.invoice:
            total_cost = instance.invoice.total_amount
        elif hasattr(instance, 'estimate') and instance.estimate:
            total_cost = instance.estimate.total_estimate

        service_type = instance.booking.service.name if (instance.booking and instance.booking.service) else "General Repair"

        # 4. Create ServiceHistory entry
        ServiceHistory.objects.get_or_create(
            repair_job=instance,
            defaults={
                'vehicle': vehicle,
                'service_date': timezone.now(),
                'service_type': service_type,
                'mileage': instance.check_in_mileage,
                'mechanic': instance.mechanic,
                'cost': total_cost,
            }
        )

        # 5. Send Notification to Customer
        if hasattr(vehicle.customer, 'user'):
            Notification.objects.create(
                user=vehicle.customer.user,
                title="Repair Completed",
                message=f"Your vehicle ({vehicle.plate_number}) repair job #{instance.id} is marked as COMPLETED."
            )
