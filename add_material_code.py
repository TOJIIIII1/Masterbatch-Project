import tkinter as tk
from tkinter import ttk, messagebox
import psycopg2

class AddMaterialCode:
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
                dbname="SOHinventory",
                user="postgres",
                password="mbpi"
            )
            self.cursor = self.conn.cursor()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to connect to the database: {e}")

    def display(self, parent_frame):
        """Display the AddMaterialCode page."""
        # Clear existing widgets in the parent frame
        for widget in parent_frame.winfo_children():
            widget.destroy()

        # Input field for Material Code
        tk.Label(parent_frame, text="Enter Material Code:", font=("Arial", 12)).pack(pady=10)
        self.material_code_entry = tk.Entry(parent_frame, font=("Arial", 12))
        self.material_code_entry.pack(pady=5)

        # Input field for Qty per Packing
        tk.Label(parent_frame, text="Enter Qty per Packing:", font=("Arial", 12)).pack(pady=10)
        self.qty_entry = tk.Entry(parent_frame, font=("Arial", 12))
        self.qty_entry.pack(pady=5)

        # Add Button
        tk.Button(
            parent_frame, text="Add Material Code", command=self.add_material_code, font=("Arial", 12), bg="blue", fg="white"
        ).pack(pady=10)

        # Treeview for displaying data
        self.tree = ttk.Treeview(parent_frame, columns=("mid", "Material Code", "Qty per Packing"), show="headings", height=10)
        self.tree.heading("mid", text="ID")
        self.tree.heading("Material Code", text="Material Code")
        self.tree.heading("Qty per Packing", text="Qty per Packing")
        self.tree.column("mid", width=50, anchor="center")
        self.tree.column("Material Code", width=200, anchor="center")
        self.tree.column("Qty per Packing", width=150, anchor="center")
        self.tree.pack(pady=10)

        # Delete Button
        tk.Button(
            parent_frame, text="Delete Selected", command=self.delete_material_code, font=("Arial", 12), bg="red", fg="white"
        ).pack(pady=5)

        # Load data into the Treeview
        self.load_data()

    def add_material_code(self):
        """Add a new material code to the database."""
        # Get inputs and validate
        material_code = self.material_code_entry.get().strip().upper()
        qty_per_packing = self.qty_entry.get().strip()

        # Validate material code
        if not material_code:
            messagebox.showerror("Error", "Material Code cannot be empty!")
            return
        if not material_code.isalnum():
            messagebox.showerror("Error", "Material Code must not contain symbols!")
            return

        # Default quantity to 0 if not provided
        if not qty_per_packing:
            qty_per_packing = 0
        elif not qty_per_packing.isdigit():
            messagebox.showerror("Error", "Qty per Packing must be a valid number!")
            return

        try:
            # Insert data into the database
            self.cursor.execute(
                "INSERT INTO material_codes (material_code, qty_per_packing) VALUES (%s, %s)",
                (material_code, int(qty_per_packing))
            )
            self.conn.commit()

            # Clear input fields
            self.material_code_entry.delete(0, tk.END)
            self.qty_entry.delete(0, tk.END)

            # Reload data in the Treeview
            self.load_data()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to add material code: {e}")

    def load_data(self):
        """Load material codes from the database into the Treeview."""
        # Clear existing data in the Treeview
        for row in self.tree.get_children():
            self.tree.delete(row)

        try:
            self.cursor.execute("SELECT * FROM material_codes")
            rows = self.cursor.fetchall()
            for row in rows:
                self.tree.insert("", tk.END, values=row)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to fetch data: {e}")

    def delete_material_code(self):
        """Delete a selected material code from the database."""
        selected_item = self.tree.selection()
        if not selected_item:
            messagebox.showerror("Error", "No item selected!")
            return

        try:
            item = self.tree.item(selected_item)
            material_code_mid = item["values"][0]
            self.cursor.execute("DELETE FROM material_codes WHERE mid = %s", (material_code_mid,))
            self.conn.commit()
            self.load_data()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to delete material code: {e}")

    def close_db_connection(self):
        """Close the database connection."""
        if self.conn:
            self.cursor.close()
            self.conn.close()
