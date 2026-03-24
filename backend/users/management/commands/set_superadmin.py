from django.core.management.base import BaseCommand
from users.models import Profile

class Command(BaseCommand):
    help = "Promotes a given user email to superadmin status (bypassing Django Admin)."

    def add_arguments(self, parser):
        parser.add_argument('email', type=str, help="The email address of the user to promote.")

    def handle(self, *args, **kwargs):
        email = kwargs['email']
        try:
            profile = Profile.objects.get(email=email)
            if profile.is_admin:
                self.stdout.write(self.style.WARNING(f"User {email} is already an admin!"))
            else:
                profile.is_admin = True
                profile.save()
                self.stdout.write(self.style.SUCCESS(f"Successfully promoted {email} to Super Admin!"))
        except Profile.DoesNotExist:
            self.stdout.write(self.style.ERROR(f"Error: No profile found matching email '{email}'."))
