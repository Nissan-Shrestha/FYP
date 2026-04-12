@echo off
cd /d "%~dp0"
python manage.py send_daily_reminders
pause
