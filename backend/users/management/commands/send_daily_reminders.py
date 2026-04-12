from django.core.management.base import BaseCommand
from django.utils import timezone
from users.models import Profile, Schedule
from users.utils import send_push_notification

class Command(BaseCommand):
    help = 'Sends morning outfit reminders to users who have scheduled outfits for today.'

    def handle(self, *args, **options):
        today = timezone.now().date()
        self.stdout.write(f"Checking for reminders for: {today}")

        # Get all profiles with an FCM token
        profiles = Profile.objects.filter(fcm_token__isnull=False)
        count = 0

        for profile in profiles:
            # Count schedules for this profile for today
            schedules_today = Schedule.objects.filter(owner=profile, date_time__date=today)
            num_outfits = schedules_today.count()

            if num_outfits > 0:
                self.stdout.write(f"Sending reminder to {profile.username} ({num_outfits} outfits)")
                
                title = "Your Style Guide for Today 🌤️"
                if num_outfits == 1:
                    body = f"Good morning {profile.username}! You have 1 outfit planned for today. Ready to suit up?"
                else:
                    body = f"Rise and shine {profile.username}! You have {num_outfits} outfits planned for today. Check your schedule!"

                send_push_notification(
                    fcm_token=profile.fcm_token,
                    title=title,
                    body=body,
                    data={"type": "daily_reminder", "date": str(today)}
                )
                count += 1
            else:
                self.stdout.write(f"Nudging {profile.username} to plan their day")
                send_push_notification(
                    fcm_token=profile.fcm_token,
                    title="Plan Your Look! 👗",
                    body=f"Hey {profile.username}, your wardrobe is waiting! Schedule an outfit for today to track your style trends.",
                    data={"type": "plan_nudge", "date": str(today)}
                )
                count += 1

        self.stdout.write(self.style.SUCCESS(f"Successfully sent {count} reminders."))
