from rest_framework import permissions
from .models import User

class IsAdmin(permissions.BasePermission):
    """Allows access only to Admin users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and (request.user.role == User.Role.ADMIN or request.user.is_superuser))


class IsReceptionist(permissions.BasePermission):
    """Allows access only to Receptionist users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.RECEPTIONIST)


class IsMechanic(permissions.BasePermission):
    """Allows access only to Mechanic users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.MECHANIC)


class IsCustomer(permissions.BasePermission):
    """Allows access only to Customer users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.CUSTOMER)


class IsAdminOrReceptionist(permissions.BasePermission):
    """Allows access to Admin or Receptionist users."""
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and (
                request.user.role in [User.Role.ADMIN, User.Role.RECEPTIONIST] or request.user.is_superuser
            )
        )


class IsStaffUser(permissions.BasePermission):
    """Allows access to Admin, Receptionist, or Mechanic users."""
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and (
                request.user.role in [User.Role.ADMIN, User.Role.RECEPTIONIST, User.Role.MECHANIC] or request.user.is_superuser
            )
        )


class IsOwnerOrStaff(permissions.BasePermission):
    """
    Allows full access to Staff (Admin/Receptionist/Mechanic).
    Customers can only view/edit their own resources.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if request.user.role in [User.Role.ADMIN, User.Role.RECEPTIONIST, User.Role.MECHANIC] or request.user.is_superuser:
            return True
            
        # Check object ownership for customer
        if hasattr(obj, 'user'):
            return obj.user == request.user
        elif hasattr(obj, 'customer'):
            return obj.customer.user == request.user
        elif hasattr(obj, 'vehicle'):
            return obj.vehicle.customer.user == request.user
        return False
