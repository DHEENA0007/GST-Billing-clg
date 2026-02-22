from rest_framework import viewsets, permissions
from django.contrib.auth.models import User
from .auth_serializers import UserSerializer
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import UserProfile

class IsAdminUser(permissions.BasePermission):
    """Allows access only to admin users."""
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

    def create(self, request):
        """Create a new user and assign a role."""
        username = request.data.get('username', '').strip()
        password = request.data.get('password', '').strip()
        email = request.data.get('email', '').strip()
        first_name = request.data.get('first_name', '').strip()
        last_name = request.data.get('last_name', '').strip()
        role = request.data.get('role', 'SALES')
        phone = request.data.get('phone', '').strip()

        if not username or not password:
            return Response({"detail": "Username and password are required."}, status=status.HTTP_400_BAD_REQUEST)

        if len(password) < 6:
            return Response({"detail": "Password must be at least 6 characters."}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=username).exists():
            return Response({"detail": f"Username '{username}' already exists."}, status=status.HTTP_400_BAD_REQUEST)

        if role not in dict(UserProfile.ROLE_CHOICES).keys():
            return Response({"detail": "Invalid role."}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(
            username=username, password=password,
            email=email, first_name=first_name, last_name=last_name
        )
        UserProfile.objects.create(user=user, role=role, phone=phone)

        serializer = UserSerializer(user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def partial_update(self, request, pk=None):
        user = get_object_or_404(User, pk=pk)
        
        if user == request.user:
            return Response({"detail": "You cannot change your own role."}, status=status.HTTP_400_BAD_REQUEST)

        role = request.data.get('role')
        if role not in dict(UserProfile.ROLE_CHOICES).keys():
            return Response({"detail": "Invalid role."}, status=status.HTTP_400_BAD_REQUEST)

        profile, created = UserProfile.objects.get_or_create(user=user)
        profile.role = role
        profile.save()

        # Also update user fields if provided
        if 'first_name' in request.data:
            user.first_name = request.data['first_name']
        if 'last_name' in request.data:
            user.last_name = request.data['last_name']
        if 'email' in request.data:
            user.email = request.data['email']
        if 'phone' in request.data:
            profile.phone = request.data['phone']
            profile.save()
        user.save()

        serializer = UserSerializer(user)
        return Response(serializer.data)
        
    def destroy(self, request, pk=None):
        user = get_object_or_404(User, pk=pk)
        
        if user == request.user:
            return Response({"detail": "You cannot delete your own account."}, status=status.HTTP_400_BAD_REQUEST)
            
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
