import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.contrib.auth.models import User
from core.models import UserProfile

username = "admin"
password = "password123"
email = "admin@company.com"

if not User.objects.filter(username=username).exists():
    user = User.objects.create_superuser(username=username, email=email, password=password)
    UserProfile.objects.get_or_create(user=user, defaults={'role': 'ADMIN', 'phone': '+91 9876543210'})
    print(f"User '{username}' created successfully.")
else:
    user = User.objects.get(username=username)
    user.set_password(password)
    user.save()
    profile, _ = UserProfile.objects.get_or_create(user=user)
    profile.role = 'ADMIN'
    profile.save()
    print(f"User '{username}' already exists. Password and role updated.")
