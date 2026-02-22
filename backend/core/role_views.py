from rest_framework import viewsets, permissions
from django.contrib.auth.models import User
from .auth_serializers import UserSerializer
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import UserProfile

class IsAdminUser(permissions.BasePermission):
    """
    Allows access only to admin users.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and 
                   hasattr(request.user, 'profile') and 
                   request.user.profile.role == 'ADMIN')

class RoleManagementViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminUser]

    def list(self, request):
        users = User.objects.all().order_by('-date_joined')
        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)

    def partial_update(self, request, pk=None):
        user = get_object_or_404(User, pk=pk)
        
        # Don't let an admin change their own role here to prevent locking themselves out
        if user == request.user:
            return Response({"detail": "You cannot change your own role."}, status=status.HTTP_400_BAD_REQUEST)

        role = request.data.get('role')
        if role not in dict(UserProfile.ROLE_CHOICES).keys():
            return Response({"detail": "Invalid role."}, status=status.HTTP_400_BAD_REQUEST)

        # Update or create profile
        profile, created = UserProfile.objects.get_or_create(user=user)
        profile.role = role
        profile.save()

        serializer = UserSerializer(user)
        return Response(serializer.data)
        
    def destroy(self, request, pk=None):
        user = get_object_or_404(User, pk=pk)
        
        # Prevent self-deletion
        if user == request.user:
            return Response({"detail": "You cannot delete your own account."}, status=status.HTTP_400_BAD_REQUEST)
            
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
