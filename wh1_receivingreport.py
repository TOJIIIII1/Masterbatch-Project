import psycopg2
import ttkbootstrap as ttk
from tkinter import messagebox
from ttkbootstrap.constants import *
from tkinter import messagebox, Canvas, Scrollbar, Frame


def format_date_input(event):
    """Format date as MM/DD/YYYY while the user types."""
    entry = event.widget
    date_text = entry.get().replace("/", "")  # Remove existing slashes
    formatted_date = ""

    # Format the input step by step
    if len(date_text) > 0:
        formatted_date += date_text[:2]  # Add MM
    if len(date_text) > 2:
        formatted_date += "/" + date_text[2:4]  # Add DD
    if len(date_text) > 4:
        formatted_date += "/" + date_text[4:8]  # Add YYYY

    # Prevent accidental deletion of text
    cursor_position = entry.index("insert")  # Save the cursor position
    entry.delete(0, "end")
    entry.insert(0, formatted_date[:10])  # Limit to MM/DD/YYYY
    if cursor_position < len(formatted_date):
        entry.icursor(cursor_position)  # Restore the cursor position

class Wh1ReceivingReport:
    def __init__(self):
        self.conn = None
        self.cursor = None
        self.connect_db()

    def connect_db(self):
        """Establish a connection to the PostgreSQL database and create a cursor."""
        try:
            if self.conn is None or self.conn.closed != 0:
                # Reconnect to the database if the connection is closed
                self.conn = psycopg2.connect(
                    host="192.168.1.13",
                    port=5432,
                    dbname="SOHinventory",
                    user="postgres",
                    password="mbpi"
                )
                self.cursor = self.conn.cursor()
                print("Database connection established.")
            elif self.cursor is None or self.cursor.closed:
                # Recreate cursor if it is closed
                self.cursor = self.conn.cursor()
                print("Database cursor re-established.")
        except Exception as e:
            print(f"Error connecting to database: {e}")

    def fetch_material_codes(self):
        """Fetch distinct material codes from the database for the dropdown."""
        try:
            query = "SELECT material_code FROM material_codes;"
            self.cursor.execute(query)
            return [row[0] for row in self.cursor.fetchall()]
        except Exception as e:
            print(f"Error fetching material codes: {e}")
            return []

    def fetch_data_from_wh1_receiving_report(self):
        """Fetch the latest data from Table 1 with date format MM/DD/YYYY."""
        try:
            query = """
                SELECT wh1_receiving_report.reference_no, 
                       TO_CHAR(wh1_receiving_report.date_received, 'MM/DD/YYYY') AS date_received, 
                       material_codes.material_code, 
                       wh1_receiving_report.quantity, 
                       wh1_receiving_report.area_location 
                FROM wh1_receiving_report
                INNER JOIN material_codes
                    ON wh1_receiving_report.material_code = material_codes.mid;
            """
            self.cursor.execute(query)
            return self.cursor.fetchall()
        except psycopg2.InterfaceError as e:
            print(f"Cursor error: {e}")
            self.connect_db()  # Reconnect if cursor is closed
            self.cursor.execute(query)
            return self.cursor.fetchall()
        except Exception as e:
            print(f"Error fetching data: {e}")
            return []

    def update_treeview(self, treeview, data, column_names):
        """Update the Treeview with the latest data."""
        treeview.delete(*treeview.get_children())  # Clear existing data
        for row in data:
            treeview.insert("", "end", values=row)

    def display(self, parent_frame):
        # Clear existing widgets in the parent frame
        for widget in parent_frame.winfo_children():
            widget.destroy()

        # Define a custom style
        style = ttk.Style()
        style.configure(
            "Custom.TLabel",
            background="#3e3f3a",  # Background color
            foreground="white",  # Font color
            font=("Arial", 30, "bold"),  # Font style and size
            anchor="center"  # Text alignment
        )

        # Title Label (with the custom style)
        label = ttk.Label(parent_frame, text="Receiving Form", style="Custom.TLabel")
        label.grid(row=0, column=0, columnspan=2, pady=5, sticky="ew")

        # Search Bar Frame
        search_frame = ttk.Frame(parent_frame)
        search_frame.grid(row=1, column=0, columnspan=3, pady=10)

        search_label = ttk.Label(search_frame, text="Search:", font=("Arial", 12))
        search_label.pack(side="left", padx=5)

        search_entry = ttk.Entry(search_frame, width=30)
        search_entry.pack(side="left", padx=5)

        # Bind key release event to the search bar
        search_entry.bind("<KeyRelease>",
                          lambda event: self.search_table(wh1_receiving_report, search_entry.get()))

        # Table Frame (with Scrollbar)
        table_frame = ttk.Frame(parent_frame)
        table_frame.grid(row=2, column=0, columnspan=3, padx=10, pady=10, sticky="nsew")

        scrollbar = ttk.Scrollbar(table_frame, orient="vertical")
        scrollbar.pack(side="right", fill="y")

        column_names_wh1_receiving_report = [
            "Reference No.", "Date Received", "Material Code", "Quantity", "Area Location"
        ]
        wh1_receiving_report = ttk.Treeview(
            table_frame,
            columns=column_names_wh1_receiving_report,
            show="headings",
            yscrollcommand=scrollbar.set,
            height=15
        )
        scrollbar.config(command=wh1_receiving_report.yview)

        for col_name in column_names_wh1_receiving_report:
            wh1_receiving_report.heading(col_name, text=col_name)
            wh1_receiving_report.column(col_name, width=150, anchor="center")
        wh1_receiving_report.pack(fill="both", expand=True)

        # Fetch data and populate the table
        data_wh1_receiving_report = self.fetch_data_from_wh1_receiving_report()
        self.update_treeview(wh1_receiving_report, data_wh1_receiving_report,
                             column_names_wh1_receiving_report)

        # Entry Fields
        entry_label = ttk.Label(parent_frame, text="Entry Fields", font=("Arial", 16, "bold"))
        entry_label.grid(row=3, column=0, columnspan=3, pady=10)

        entry_frame = ttk.Frame(parent_frame)
        entry_frame.grid(row=4, column=0, columnspan=3, pady=10)

        wh1_receiving_report_entries = []
        material_codes = self.fetch_material_codes()

        for i, label_text in enumerate(column_names_wh1_receiving_report):
            col_label = ttk.Label(entry_frame, text=label_text, font=("Arial", 12))
            col_label.grid(row=0, column=i, padx=10, pady=5)

            if label_text == "Date Received":
                date_entry = ttk.Entry(entry_frame, width=15)
                date_entry.grid(row=1, column=i, padx=10, pady=5)
                date_entry.bind("<KeyRelease>", format_date_input)  # Bind the formatting function
                wh1_receiving_report_entries.append(date_entry)
            elif label_text == "Material Code":
                combobox = ttk.Combobox(entry_frame, values=material_codes, width=15)
                combobox.grid(row=1, column=i, padx=10, pady=5)
                wh1_receiving_report_entries.append(combobox)
            else:
                entry = ttk.Entry(entry_frame, width=15)
                entry.grid(row=1, column=i, padx=10, pady=5)
                wh1_receiving_report_entries.append(entry)

        self.wh1_receiving_report_entries = wh1_receiving_report_entries

        # Buttons Frame
        button_frame = ttk.Frame(parent_frame)
        button_frame.grid(row=5, column=0, columnspan=3, pady=10)

        add_button = ttk.Button(
            button_frame,
            text="Add",
            command=lambda: self.add_row_wh1_receiving_report(wh1_receiving_report),
            width=10
        )
        add_button.grid(row=0, column=0, padx=5)

        update_button = ttk.Button(
            button_frame,
            text="Update",
            command=lambda: self.update_row_wh1_receiving_report(wh1_receiving_report),
            width=10
        )
        update_button.grid(row=0, column=1, padx=5)

        delete_button = ttk.Button(
            button_frame,
            text="Delete",
            command=lambda: self.delete_row_wh1_receiving_report(wh1_receiving_report),
            width=10
        )
        delete_button.grid(row=0, column=2, padx=5)

        # Center Table, Labels, and Entry Fields
        parent_frame.grid_columnconfigure(0, weight=1)
        parent_frame.grid_rowconfigure(2, weight=1)

        entry_frame.grid_columnconfigure(0, weight=1)
        entry_frame.grid_columnconfigure(len(column_names_wh1_receiving_report) - 1, weight=1)

    def add_row_wh1_receiving_report(self, table):
        try:
            self.connect_db()  # Ensure the connection is open

            # Retrieve values from entry fields for Table 1
            reference_no = self.wh1_receiving_report_entries[0].get()
            date_received = self.wh1_receiving_report_entries[1].get()
            material_code = self.wh1_receiving_report_entries[2].get()
            quantity = self.wh1_receiving_report_entries[3].get()
            area_location = self.wh1_receiving_report_entries[4].get()

            # Ensure inputs are not empty
            if not reference_no or not date_received or not material_code or not quantity or not area_location:
                messagebox.showwarning("Missing Fields", "Please fill in all fields before adding.")
                return

            # Ensure quantity is a valid integer
            try:
                quantity = int(quantity)  # Convert to integer
            except ValueError:
                messagebox.showwarning("Invalid Input", "Quantity must be a number.")
                return

            # Get material_code_id from the material_codes table
            get_material_id = "SELECT mid FROM material_codes WHERE material_code = %s"
            self.cursor.execute(get_material_id, (material_code,))
            material_code_id = self.cursor.fetchone()

            if material_code_id is None:
                messagebox.showerror("Error", f"Material code '{material_code}' not found in the database.")
                return

            material_code_id = material_code_id[0]  # Extract the ID from the tuple

            # Insert a new row into PostgreSQL (wh1_receiving_report table)
            query = """INSERT INTO wh1_receiving_report (reference_no, date_received, material_code, quantity, area_location) 
                       VALUES (%s, %s, %s, %s, %s)"""
            values = (reference_no, date_received, material_code_id, quantity, area_location)
            self.cursor.execute(query, values)
            self.conn.commit()

            messagebox.showinfo("Success", "Row added successfully to Table 1.")

            # After adding the row, refresh the Treeview to show the updated data
            data_wh1_receiving_report = self.fetch_data_from_wh1_receiving_report()
            self.update_treeview(table, data_wh1_receiving_report,
                                 ["Reference No.", "Date Received", "Material Code", "Quantity", "Area Location"])

        except Exception as e:
            messagebox.showerror("Error", f"Error while adding row to Table 1: {e}")
            self.conn.rollback()  # Rollback the transaction if there's an error
        finally:
            self.close_connection()

    def update_row_wh1_receiving_report(self, table):
        try:
            self.connect_db()  # Ensure the connection is open

            # Get selected row
            selected_item = table.selection()
            if not selected_item:
                messagebox.showwarning("No Selection", "Please select a row to update.")
                return

            # Retrieve values from entry fields for Table 1
            reference_no = self.wh1_receiving_report_entries[0].get()
            date_received = self.wh1_receiving_report_entries[1].get()
            material_code = self.wh1_receiving_report_entries[2].get()
            quantity = self.wh1_receiving_report_entries[3].get()
            area_location = self.wh1_receiving_report_entries[4].get()

            # Get material_code_id from the material_codes table
            get_material_id = "SELECT mid FROM material_codes WHERE material_code = %s"
            self.cursor.execute(get_material_id, (material_code,))
            material_code_id = self.cursor.fetchone()

            # Construct the query dynamically based on which fields have values
            query = "UPDATE wh1_receiving_report SET "
            values = []

            # Only add fields that have values
            if reference_no:
                query += "reference_no = %s, "
                values.append(reference_no)
            if date_received:
                query += "date_received = %s, "
                values.append(date_received)
            if material_code:
                query += "material_code = %s, "
                values.append(material_code_id)
            if quantity:
                query += "quantity = %s, "
                values.append(int(quantity))  # Ensure quantity is an integer
            if area_location:
                query += "area_location = %s, "
                values.append(area_location)

            # Remove trailing comma and space
            query = query.rstrip(", ")

            # Use reference_no as the unique identifier (ID) in the WHERE clause
            query += " WHERE reference_no = %s"
            values.append(reference_no)

            # Execute the query
            self.cursor.execute(query, tuple(values))
            self.conn.commit()

            messagebox.showinfo("Success", "Row updated successfully in Table 1.")

            # Refresh the Treeview to show updated data
            data_wh1_receiving_report = self.fetch_data_from_wh1_receiving_report()
            self.update_treeview(table, data_wh1_receiving_report,
                                 ["Reference No.", "Date Received", "Material Code", "Quantity", "Area Location"])

        except Exception as e:
            messagebox.showerror("Error", f"Error while updating row in Table 1: {e}")
            self.conn.rollback()  # Rollback the transaction if there's an error
        finally:
            self.close_connection()

    def delete_row_wh1_receiving_report(self, table):
        try:
            self.connect_db()  # Ensure the connection is open

            # Get selected row
            selected_item = table.selection()
            if not selected_item:
                messagebox.showwarning("No Selection", "Please select a row to delete.")
                return

            # Get the reference_no (used as the unique identifier) of the selected row
            reference_no = table.item(selected_item)['values'][0]  # Assuming first column is reference_no (text)

            # Debugging: Check the reference_no value
            print(f"Selected Reference No: {reference_no}")

            # Ask for confirmation
            confirm = messagebox.askyesno("Confirm Delete",
                                          f"Are you sure you want to delete the row with Reference No: {reference_no}?")
            if not confirm:
                return

            # Ensure reference_no is treated as text (explicitly casting to TEXT in SQL)
            query = "DELETE FROM wh1_receiving_report WHERE reference_no = %s::TEXT"

            # Debugging: Check the query and parameter
            print(f"SQL Query: {query} - Reference No: {reference_no}")

            # Execute the delete query
            self.cursor.execute(query, (reference_no,))  # Treat reference_no as text
            self.conn.commit()

            messagebox.showinfo("Success", f"Row with Reference No: {reference_no} deleted successfully.")

            # Refresh the Treeview to show the updated data
            data_wh1_receiving_report = self.fetch_data_from_wh1_receiving_report()
            self.update_treeview(table, data_wh1_receiving_report,
                                 ["Reference No.", "Date Received", "Material Code", "Quantity", "Area Location"])

        except Exception as e:
            messagebox.showerror("Error", f"Error while deleting row in Table 1: {e}")
            self.conn.rollback()  # Rollback the transaction if there's an error
        finally:
            self.close_connection()

    def search_table(self, table, search_text):
        """Filter the table based on the search text."""
        try:
            # Clear the existing table data
            for row in table.get_children():
                table.delete(row)

            # Ensure database connection is active
            self.connect_db()

            # Query the database for matching results, casting columns to text for ILIKE
            query = """
            SELECT reference_no, 
                   TO_CHAR(date_received, 'MM/DD/YYYY') AS date_received, 
                   material_code, 
                   quantity, 
                   area_location 
            FROM wh1_receiving_report
            WHERE reference_no::TEXT ILIKE %s OR material_code::TEXT ILIKE %s;
            """
            self.cursor.execute(query, (f"%{search_text}%", f"%{search_text}%"))
            results = self.cursor.fetchall()

            # Populate the table with filtered results
            for row in results:
                table.insert("", "end", values=row)

        except psycopg2.Error as e:
            # Handle database errors
            print(f"Database error: {e}")
            messagebox.showerror("Database Error", "An error occurred while searching the database.")
            self.conn.rollback()  # Rollback the transaction to recover

        finally:
            self.close_connection()  # Ensure the connection is properly closed

    def close_connection(self):
        """Close the connection and cursor."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("Connection closed.")
