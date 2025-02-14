import datetime


def schedule_clear_task(self):
    """Schedule the clear function to run every 24 hours starting at 8:00 AM."""
    now = datetime.datetime.now()
    target_time = now.replace(hour=14, minute=0, second=0, microsecond=0)

    if now > target_time:
        # If it's past 8:00 AM today, schedule for tomorrow
        target_time += datetime.timedelta(days=1)

    delay = (target_time - now).total_seconds() * 1000  # Convert to milliseconds

    # Schedule the first run
    self.root.after(int(delay), self.run_clear_task)

def run_clear_task(self):
    """Runs the clearing function and reschedules itself for the next day."""
    self.app_instance.clear_all_pages(clear_ui_only=True)  # ✅ Corrected function name & removed extra argument

    # Schedule the next execution in 24 hours (86400000 milliseconds)
    self.root.after(86400000, self.run_clear_task)
