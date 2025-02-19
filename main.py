from tkinter import Canvas, StringVar

import ttkbootstrap as ttk
from ttkbootstrap.constants import *

from Warehouse1.wh1_receivingreport import Wh1ReceivingReport
from Warehouse1.wh1_transfer_form import Wh1TransferForm
from Warehouse1.wh1_outgoingreport import Wh1OutgoingReport
from Warehouse1.wh1_preparation_form import Wh1PreparationForm
from Warehouse1.add_material_code import AddMaterialCode

from Warehouse2.Spreadsheet_wh2 import Spreadsheet2
from Warehouse2.wh2_receivingreport import Wh2ReceivingReport
from Warehouse2.wh2_transfer_form import Wh2TransferForm
from Warehouse2.wh2_outgoingreport import Wh2OutgoingReport
from Warehouse2.wh2_preparation_form import Wh2PreparationForm
from Warehouse2.wh2_add_material_code import Wh2AddMaterialCode

from Warehouse4.Spreadsheet_wh4 import Spreadsheet4
from Warehouse4.wh4_receiving_report import Wh4ReceivingReport
from Warehouse4.wh4_transfer_form import Wh4TransferForm
from Warehouse4.wh4_outgoingreport import Wh4OutgoingReport
from Warehouse4.wh4_preparation_form import Wh4PreparationForm
from Warehouse4.wh4_add_material import Wh4AddMaterialCode

from Warehouse1.Spreedsheet_wh1 import Spreadsheet1
from Notes import Notes
import datetime

class MainApp:
    #sadjfhaskjasdasdasdasd hello
    def __init__(self):
        self.themes = [
            "solar", "cyborg", "darkly", "superhero", "vapor",  # Dark themes
            "flatly", "litera", "minty", "pulse", "sandstone", "yeti"  # Light themes
        ]

        # Initialize the main app window with a default theme
        self.root = ttk.Window(themename="solar")
        self.root.title("Modern Navigation App")
        self.root.geometry("1100x600")

        # Schedule the auto-clear function
        self.schedule_clear_task()

        # Define subpages for dropdown menus
        self.subpages = {
            "Warehouse 1": {
                "Receiving Report": Wh1ReceivingReport(),
                "Transfer Form": Wh1TransferForm(),
                "Outgoing Report": Wh1OutgoingReport(),
                "Preparation Form": Wh1PreparationForm(),
                "Add Material Code": AddMaterialCode(),
            },
            "Warehouse 2": {
                "Receiving Report": Wh2ReceivingReport(),
                "Transfer Form": Wh2TransferForm(),
                "Outgoing Report": Wh2OutgoingReport(),
                "Preparation Form": Wh2PreparationForm(),
                "Add Material Code": Wh2AddMaterialCode(),
            },
            "Warehouse 4": {
                "Receiving Report": Wh4ReceivingReport(),
                "Transfer Form": Wh4TransferForm(),
                "Outgoing Report": Wh4OutgoingReport(),
                "Preparation Form": Wh4PreparationForm(),
                "Add Material Code": Wh4AddMaterialCode(),
            },
            "Reports": {
                "Notes": Notes(),
                "Warehouse 1: SOH Summary": Spreadsheet1(),
                "Warehouse 2: SOH Summary": Spreadsheet2(),
                "Warehouse 4: SOH Summary": Spreadsheet4(),

            },
        }

        # Create a canvas with a black background
        self.canvas = Canvas(self.root, width=1100, height=600, bg="black")
        self.canvas.place(x=0, y=0, relwidth=1, relheight=1)  # Set full size

        # Create UI layout
        self.create_ui()

        # Apply Treeview column header highlight style
        self.style = ttk.Style()
        self.style.configure(
            "Treeview.Heading",
            background="#3e3f3a",  # Header background color
            foreground="white",    # Header text color
            font=("Segoe UI", 14, "bold"),  # Header text style
        )
        self.style.map("Treeview.Heading", background=[('active', '#3e3f3a')])  # Highlight color on hover

    def create_ui(self):
        # Sidebar (Navigation)
        self.sidebar = ttk.Frame(self.root, bootstyle=SECONDARY, width=200)
        self.sidebar.pack(side="left", fill="y")

        # Logo
        self.logo = ttk.Label(
            self.sidebar,
            text="Masterbatch",
            bootstyle=INVERSE,
            font=("Helvetica", 18, "bold")
        )
        self.logo.pack(pady=30)

        # Dropdown menus in the navigation bar
        for category, subpages in self.subpages.items():
            dropdown_button = ttk.Menubutton(
                self.sidebar,
                text=category,
                bootstyle=OUTLINE,
                menu=self.create_dropdown_menu(subpages)
            )
            dropdown_button.pack(fill="x", pady=5, padx=10)

        # Main content area
        self.main_content = ttk.Frame(self.root, bootstyle=LIGHT)
        self.main_content.pack(side="right", expand=True, fill="both")

        # Set background color for main content
        self.main_content.configure(style="Black.TFrame")

        # Show the first subpage by default
        first_category = next(iter(self.subpages.values()))
        first_subpage = next(iter(first_category.values()))
        self.show_page(first_subpage)

        # Settings Button
        settings_button = ttk.Button(
            self.sidebar, text="⚙ Change Theme", bootstyle=OUTLINE, command=self.open_settings
        )
        settings_button.pack(fill="x", pady=10, padx=10)

    def create_dropdown_menu(self, subpages):
        """Create a dropdown menu for navigation."""
        menu = ttk.Menu()
        for subpage_name, subpage_instance in subpages.items():
            menu.add_command(
                label=subpage_name,
                command=lambda page=subpage_instance: self.show_page(page)
            )
        return menu

    def open_settings(self):
        """ Open a settings window to change the theme dynamically. """
        settings_window = ttk.Toplevel(self.root)
        settings_window.title("Settings")
        settings_window.geometry("300x150")

        # Label
        label = ttk.Label(settings_window, text="Select Theme:", font=("Arial", 12))
        label.pack(pady=10)

        # Dropdown Menu for Themes
        selected_theme = StringVar(value="solar")  # Default theme
        theme_dropdown = ttk.Combobox(settings_window, values=self.themes, textvariable=selected_theme)
        theme_dropdown.pack(pady=5)

        # Apply Button
        apply_button = ttk.Button(
            settings_window, text="Apply Theme", bootstyle=PRIMARY,
            command=lambda: self.change_theme(selected_theme.get(), settings_window)
        )
        apply_button.pack(pady=10)

    def change_theme(self, new_theme, window):
        """ Change the theme dynamically and close the settings window. """
        self.root.style.theme_use(new_theme)
        window.destroy()

    def show_page(self, page_instance):
        """Clear the main content area and display the selected page."""
        for widget in self.main_content.winfo_children():
            widget.destroy()  # Remove existing widgets

        page_instance.display(self.main_content)

    def clear_all_pages(self, clear_ui_only=True):
        """Clears rows and marks them as deleted in the database."""
        try:
            print("Auto-clearing rows at 8:00 AM...")

            if clear_ui_only:
                print("Clearing UI table...")

                # Simulate clearing the database
                query = "UPDATE wh1_receiving_report SET deleted = TRUE WHERE deleted = FALSE;"
                print("All rows marked as deleted in the database.")

        except Exception as e:
            print(f"Error while clearing rows: {e}")

    def schedule_clear_task(self):
        """Schedule the clear function to run every 24 hours starting at 8:00 AM."""
        now = datetime.datetime.now()
        target_time = now.replace(hour=14, minute=0, second=0, microsecond=0)

        if now > target_time:
            # If it's past 8:00 AM today, schedule for tomorrow
            target_time += datetime.timedelta(days=1)

        delay = (target_time - now).total_seconds() * 1000  # Convert to milliseconds
        self.root.after(int(delay), self.run_clear_task)  # Schedule first execution

    def run_clear_task(self):
        """Runs the clearing function and reschedules itself for the next day."""
        self.clear_all_pages(clear_ui_only=True)  # ✅ Call `clear_all_pages`
        self.root.after(86400000, self.run_clear_task)  # Schedule next run in 24 hours


    def run(self):
        # Run the app
        self.root.mainloop()


if __name__ == "__main__":
    app = MainApp()
    app.run()
