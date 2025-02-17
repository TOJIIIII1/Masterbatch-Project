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
                host="192.168.1.224",
                port=5432,
                dbname="Inventory",
                user="postgres",
                password="newpassword"
            )
            self.cursor = self.conn.cursor()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to connect to the database: {e}")

    def display(self, parent_frame):
        """Display the AddMaterialCode page with a search bar and wider treeview."""
        # Clear existing widgets
        for widget in parent_frame.winfo_children():
            widget.destroy()

        # Call add_all_material_codes to ensure data is loaded from material_codes to wh2_material_codes
        self.add_all_material_codes()

        # Header Label
        tk.Label(parent_frame, text="Material Code Management", font=("Arial", 18, "bold"), pady=10).pack()

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

        # Frame for Entry Fields and Buttons
        input_frame = tk.Frame(parent_frame)
        input_frame.pack(pady=20)

        tk.Label(input_frame, text="Enter Material Code:", font=("Arial", 12)).grid(row=0, column=0, padx=10, pady=5,
                                                                                    sticky="e")
        self.material_code_entry = tk.Entry(input_frame, font=("Arial", 12), width=30)
        self.material_code_entry.grid(row=0, column=1, padx=10, pady=5, sticky="w")

        # Frame for Buttons
        button_frame = tk.Frame(parent_frame)
        button_frame.pack(pady=10)

        tk.Button(button_frame, text="Add Material Code", command=self.add_material_code, font=("Arial", 12), bg="blue",
                  fg="white", width=20).grid(row=0, column=0, padx=10)

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

    def add_material_code(self):
        """Add a new material code to the database."""
        # Get inputs and validate
        material_code = self.material_code_entry.get().strip().upper()

        # Validate material code
        if not material_code:
            messagebox.showerror("Error", "Material Code cannot be empty!")
            return
        if not material_code.isalnum():
            messagebox.showerror("Error", "Material Code must not contain symbols!")
            return

        try:
            # Insert data into the database without 'area_location'
            self.cursor.execute(
                "INSERT INTO wh4_material_codes (material_code, qty_per_packing) VALUES (%s, %s)",
                (material_code, 0)
            )
            self.conn.commit()

            # Clear input fields
            self.material_code_entry.delete(0, tk.END)

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
            # Update query to exclude area_location
            self.cursor.execute("SELECT mid, material_code, qty_per_packing FROM wh4_material_codes")
            rows = self.cursor.fetchall()
            for row in rows:
                self.tree.insert("", tk.END, values=row)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to fetch data: {e}")

    def add_all_material_codes(self):
        """Automatically insert all material codes (with their 'mid') from material_codes table into wh4_material_codes."""
        try:
            # Fetch all the material codes and their 'mid' from the material_codes table
            self.cursor.execute("SELECT mid, material_code, qty_per_packing FROM material_codes")
            rows = self.cursor.fetchall()

            # Loop through each row and insert or update it into the wh4_material_codes table
            for row in rows:
                material_code_mid, material_code, qty_per_packing = row

                # Use INSERT ... ON CONFLICT to insert new rows or update existing ones
                self.cursor.execute("""
                    INSERT INTO wh4_material_codes (mid, material_code, qty_per_packing)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (mid) DO UPDATE
                    SET material_code = EXCLUDED.material_code,
                        qty_per_packing = EXCLUDED.qty_per_packing
                """, (material_code_mid, material_code, qty_per_packing))

            # Commit the changes to the database
            self.conn.commit()
            print("All material codes processed successfully (inserted or updated).")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to insert or update material codes: {e}")
            print(f"{e}")
            self.conn.rollback()

    def close_db_connection(self):
        """Close the database connection."""
        if self.conn:
            self.cursor.close()
            self.conn.close()
