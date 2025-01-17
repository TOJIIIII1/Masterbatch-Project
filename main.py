import ttkbootstrap as ttk
from ttkbootstrap.constants import *
from wh1_receivingreport import Wh1ReceivingReport
from wh1_transfer_form import Wh1TransferForm
from wh1_outgoingreport import Wh1OutgoingReport
from wh1_preparation_form import Wh1PreparationForm

class MainApp:
    def __init__(self):
        # Initialize the main app window with ttkbootstrap theme
        self.root = ttk.Window(themename="sandstone")  # Applying the theme globally to the root window
        self.root.title("Modern Navigation App")
        self.root.geometry("1000x600")

        # Define subpages for dropdown menus
        self.subpages = {
            "Warehouse 1": {
                "Receiving Report": Wh1ReceivingReport(),
                "Transfer Form": Wh1TransferForm(),
                "Outgoing Report": Wh1OutgoingReport(),
                "Preparation Form": Wh1PreparationForm(),
            },
            "Warehouse 2": {
                "Receiving Report": Wh1ReceivingReport(),
                "Transfer Form": Wh1TransferForm(),
                "Outgoing Report": Wh1ReceivingReport(),
                "Preaparation Form": Wh1ReceivingReport(),
            },
            "Warehouse 4": {
                "Receiving Report": Wh1ReceivingReport(),
                "Transfer Form": Wh1TransferForm(),
                "Outgoing Report": Wh1ReceivingReport(),
                "Preaparation Form": Wh1ReceivingReport(),
            },
            "Reports": {
                "Receiving Report": Wh1ReceivingReport(),
                "Transfer Form": Wh1TransferForm(),
                "Outgoing Report": Wh1ReceivingReport(),
                "Preaparation Form": Wh1ReceivingReport(),
            },
        }

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

        # Show the first subpage by default
        first_category = next(iter(self.subpages.values()))
        first_subpage = next(iter(first_category.values()))
        self.show_page(first_subpage)

    def create_dropdown_menu(self, subpages):
        """Create a dropdown menu for navigation."""
        menu = ttk.Menu()
        for subpage_name, subpage_instance in subpages.items():
            menu.add_command(
                label=subpage_name,
                command=lambda page=subpage_instance: self.show_page(page)
            )
        return menu

    def show_page(self, page_instance):
        """Clear the main content area and display the selected page."""
        for widget in self.main_content.winfo_children():
            widget.destroy()  # Remove existing widgets

        page_instance.display(self.main_content)

    def run(self):
        # Run the app
        self.root.mainloop()


if __name__ == "__main__":
    app = MainApp()
    app.run()
