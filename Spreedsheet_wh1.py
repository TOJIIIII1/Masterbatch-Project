import tkinter as tk
import os
from tkinter import ttk, messagebox, filedialog
import psycopg2
import pandas as pd
from datetime import datetime, timedelta


class ExportTablePage:
    def __init__(self):
        self.conn = None
        self.cursor = None
        self.data = []  # Data for the table
        self.connect_to_db()

    def connect_to_db(self):
        """Connect to the PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(
                host="192.168.1.13",  # Replace with your database host
                port=5432,  # Replace with your database port
                dbname="SOHinventory",  # Replace with your database name
                user="postgres",  # Replace with your username
                password="mbpi"  # Replace with your password
            )
            self.cursor = self.conn.cursor()
            self.load_data_from_db()  # Load data after connecting
        except Exception as e:
            messagebox.showerror("Error", f"Failed to connect to the database: {e}")

    def load_data_from_db(self):
        """Fetch data from PostgreSQL, retrieve material_code_id, and load it into the table, then insert it into another table."""
        try:
            # Query to fetch material_code and quantity using LEFT JOIN
            query = """
            SELECT 
                COALESCE(m.material_code, '0') AS material_code,  -- Use '0' if no material_code is found
                COALESCE(w.quantity, 0) AS quantity,              -- Use 0 if no quantity is found
                COALESCE(m.qty_per_packing, 0) AS qty_per_packing -- Use 0 if no qty_per_packing is found
            FROM material_codes as m
            LEFT JOIN wh1_receiving_report as w
                ON m.mid = w.material_code;
            """

            self.cursor.execute(query)
            rows = self.cursor.fetchall()

            # Prepare the data with material_code and quantity (both defaults to '0' when no match is found)
            self.data = []
            for row in rows:
                material_code = row[0]
                no_of_bags = row[1]
                qty_per_packing = row[2]

                # Ensure no_of_bags and qty_per_packing are converted to float (double precision)
                try:
                    no_of_bags = float(no_of_bags) if no_of_bags is not None else 0.0
                    qty_per_packing = float(qty_per_packing) if qty_per_packing is not None else 0.0
                except (ValueError, TypeError):  # Catch invalid types and values
                    no_of_bags = 0.0  # Default to 0.0 if conversion fails
                    qty_per_packing = 0.0  # Default to 0.0 if conversion fails

                # Get material_code_id (mid) from the material_codes table
                get_material_id = "SELECT mid FROM material_codes WHERE material_code = %s"
                self.cursor.execute(get_material_id, (material_code,))
                material_code_id = self.cursor.fetchone()

                if material_code_id:
                    material_code_id = material_code_id[0]  # Extract the ID from the tuple
                else:
                    material_code_id = None  # If not found, set it to None (you can handle this as per your requirement)

                # Calculate Total (Number of Bags * Quantity per Packing)
                total = no_of_bags * qty_per_packing

                # Ensure total is a double precision (float)
                total = float(total)

                # Append data to self.data (leave area_location empty for now or provide a default)
                self.data.append(
                    (material_code_id, no_of_bags, qty_per_packing, "",
                     total))  # Area location is left empty here for now

            # Now insert this data into the `wh1_spreedsheet` table
            for record in self.data:
                material_code_id, quantity, qty_per_packing, whse1_excess, total = record

                # Ensure whse1_excess is a float (double precision)
                try:
                    whse1_excess = float(whse1_excess) if whse1_excess is not None else 0.0
                except (ValueError, TypeError):  # Catch invalid types and values
                    whse1_excess = 0.0  # Default to 0.0 if conversion fails

                # Insert into the database (wh1_spreedsheet table)
                insert_query = """
                INSERT INTO wh1_spreedsheet (material_code, no_of_bags, qty_per_packing, whse1_excess, total)
                VALUES (%s, %s, %s, %s, %s)
                """
                # Ensure values are of float type (double precision in PostgreSQL)
                values = (material_code_id, float(quantity), float(qty_per_packing), float(whse1_excess), float(total))

                # Execute the insert query
                self.cursor.execute(insert_query, values)

            # Commit the transaction after all inserts
            self.conn.commit()

            # Show success message
            messagebox.showinfo("Success", "Data inserted into the database successfully.")

        except Exception as e:
            messagebox.showerror("Error", f"Failed to fetch and insert data: {e}")
            self.conn.rollback()  # Rollback in case of error


        except Exception as e:
            messagebox.showerror("Error", f"Failed to fetch and insert data: {e}")
            self.conn.rollback()  # Rollback in case of error

    def display(self, parent_frame):
        """Display the Export Table page."""
        # Clear any existing widgets in the parent frame
        for widget in parent_frame.winfo_children():
            widget.destroy()

        # Create a frame to hold the content
        frame = ttk.Frame(parent_frame)
        frame.grid(row=0, column=0, sticky="nsew")

        # Material Code Table Header
        tk.Label(frame, text="SOH SUMMARY", font=("Arial", 25, "bold")).grid(row=0, column=0, padx=10, pady=20,
                                                                                     columnspan=5)

        # Treeview for displaying data (keeping original columns)
        self.tree = ttk.Treeview(frame, columns=(
            "Material Code", "Number of Bags", "Quantity per Packing", "WHSE #1 - Excess", "Total"),
                                 show="headings", height=10)

        # Define the columns and their headings
        self.tree.heading("Material Code", text="Material Code")
        self.tree.heading("Number of Bags", text="Number of Bags")
        self.tree.heading("Quantity per Packing", text="Quantity per Packing")
        self.tree.heading("WHSE #1 - Excess", text="WHSE #1 - Excess")
        self.tree.heading("Total", text="Total")

        # Set column widths and alignment
        self.tree.column("Material Code", width=150, anchor="center")
        self.tree.column("Number of Bags", width=150, anchor="center")
        self.tree.column("Quantity per Packing", width=180, anchor="center")
        self.tree.column("WHSE #1 - Excess", width=180, anchor="center")
        self.tree.column("Total", width=150, anchor="center")

        self.tree.grid(row=1, column=0, columnspan=5, padx=10, pady=10, sticky="nsew")

        # Load data into the Treeview
        self.load_data()

        # Export Button
        export_button = ttk.Button(frame, text="Export to Excel", command=self.export_to_excel)
        export_button.grid(row=2, column=0, columnspan=5, padx=10, pady=20, sticky="ew")

        # Make rows/columns resize dynamically
        frame.grid_rowconfigure(1, weight=1)  # Allow the Treeview to resize
        frame.grid_columnconfigure(0, weight=1)
        frame.grid_columnconfigure(1, weight=1)
        frame.grid_columnconfigure(2, weight=1)
        frame.grid_columnconfigure(3, weight=1)
        frame.grid_columnconfigure(4, weight=1)

    def load_data(self):
        """Load data into the Treeview."""
        # Clear existing data in the Treeview
        for row in self.tree.get_children():
            self.tree.delete(row)

        # Insert new data into the Treeview
        for row in self.data:
            self.tree.insert("", tk.END, values=row)

    def export_to_excel(self):
        """Export the data to an Excel file in a predefined folder."""
        if not self.data:
            messagebox.showerror("Error", "No data to export!")
            return

        # Create a pandas DataFrame from the data
        df = pd.DataFrame(self.data,
                          columns=["Material Code", "Number of Bags", "Quantity per Packing", "WHSE #1 - Excess",
                                   "Total"])

        # Predefined directory and file path
        directory = r"C:\Users\YourUsername\Documents\ExportedData"  # Replace with your desired directory
        if not os.path.exists(directory):
            os.makedirs(directory)  # Create the directory if it doesn't exist

        # Set the file name with timestamp
        file_path = os.path.join(directory, f"exported_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.xlsx")

        try:
            # Save the data to an Excel file
            df.to_excel(file_path, index=False, engine='openpyxl')
            messagebox.showinfo("Success", f"Data exported successfully to {file_path}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to export data to Excel: {e}")
