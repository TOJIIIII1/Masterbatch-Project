import tkinter as tk
from tkinter import ttk, messagebox
import psycopg2


class Wh4AddMaterialCode:
    def __init__(self):
        self.conn = None
        self.cursor = None
        self.connect_to_db()

    def connect_to_db(self):
        """Connect to the PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(
                host="192.168.1.13",
                port=5432,
                dbname="Inventory",
                user="postgres",
                password="mbpi"
            )
            self.cursor = self.conn.cursor()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to connect to the database: {e}")

    def display(self, parent_frame):
        """Display the AddMaterialCode page with a search bar and wider treeview."""
        # Clear existing widgets
        for widget in parent_frame.winfo_children():
            widget.destroy()

        # Header Label
        tk.Label(parent_frame, text="Warehouse 4: Material Code List", font=("Arial", 18, "bold"), pady=10).pack()

        # Search Bar Frame
        search_frame = tk.Frame(parent_frame)
        search_frame.pack(pady=5, fill="x")

        tk.Label(search_frame, text="Search:", font=("Arial", 12)).pack(side="left", padx=10)
        self.search_entry = tk.Entry(search_frame, font=("Arial", 12), width=30)
        self.search_entry.pack(side="left", padx=5)
        self.search_entry.bind("<KeyRelease>", self.filter_data)  # Dynamic search on key release

        # Treeview Frame (Balanced Width)
        tree_frame = tk.Frame(parent_frame, width=400)  # Adjust width here
        tree_frame.pack(pady=10)

        self.tree = ttk.Treeview(
            tree_frame, columns=("mid", "Material Code", "Qty per Packing"), show="headings", height=15
        )
        self.tree.heading("mid", text="ID")
        self.tree.heading("Material Code", text="Material Code")
        self.tree.heading("Qty per Packing", text="Qty per Packing")

        # Adjust column widths (wider than before)
        self.tree.column("mid", width=70, anchor="center")
        self.tree.column("Material Code", width=250, anchor="center")
        self.tree.column("Qty per Packing", width=180, anchor="center")

        self.tree.pack(fill="both", expand=True)

        # Load data into the Treeview
        self.load_data()

    def filter_data(self, event):
        """Filters the Treeview based on search input."""
        search_query = self.search_entry.get().strip().lower()

        # Clear the Treeview
        for row in self.tree.get_children():
            self.tree.delete(row)

        # Fetch all data and filter it
        self.cursor.execute("SELECT mid, material_code, qty_per_packing FROM wh4_material_codes")
        rows = self.cursor.fetchall()

        for row in rows:
            if search_query in str(row[1]).lower():
                self.tree.insert("", tk.END, values=row)

    def load_data(self):
        """Load material codes from the database into the Treeview."""
        # Clear existing data in the Treeview
        for row in self.tree.get_children():
            self.tree.delete(row)

        try:
            # Update query to exclude area_location
            self.cursor.execute("SELECT mid, material_code, qty_per_packing FROM wh4_material_codes")
            rows = self.cursor.fetchall()
            for row in rows:
                self.tree.insert("", tk.END, values=row)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to fetch data: {e}")

    def close_db_connection(self):
        """Close the database connection."""
        if self.conn:
            self.cursor.close()
            self.conn.close()
