import psycopg2
import ttkbootstrap as ttk
from tkinter import messagebox
from ttkbootstrap.constants import *
from tkinter import messagebox, Canvas, Scrollbar, Frame
from date_format import format_date_input
import tkinter as tk


class Wh2PreparationForm:
    def __init__(self):
        self.conn = None
        self.cursor = None
        self.connect_db()

    def connect_db(self):
        """Ensure the database connection is active and cursor is open."""
        try:
            if self.conn is None or self.conn.closed != 0:
                # Reconnect to the database if the connection is closed
                self.conn = psycopg2.connect(
                    host="192.168.1.13",
                    port=5432,
                    dbname="Inventory",
                    user="postgres",
                    password="mbpi"
                )
                self.cursor = self.conn.cursor()
                print("Database connection established.")
            elif self.cursor is None or self.cursor.closed:
                # Recreate the cursor if it is closed
                self.cursor = self.conn.cursor()
                print("Database cursor re-established.")
        except Exception as e:
            print(f"Error connecting to database: {e}")

    def fetch_material_codes(self):
        """Fetch distinct material codes from the database for the dropdown."""
        try:
            self.connect_db()  # Ensure connection is open before executing the query
            query = "SELECT material_code FROM wh2_material_codes;"
            self.cursor.execute(query)
            return [row[0] for row in self.cursor.fetchall()]
        except Exception as e:
            print(f"Error fetching material codes: {e}")
            return []

    def fetch_data_from_wh2_preparation_form(self):
        """Fetch the latest data from Table 1 with date format MM/DD/YYYY."""
        try:
            self.connect_db()  # Ensure connection is open before executing the query
            query = """
                SELECT wh2_preparation_form.reference_no, 
                       TO_CHAR(wh2_preparation_form.date, 'MM/DD/YYYY') AS date, 
                       material_codes.material_code, 
                       wh2_preparation_form.quantity_prepared, 
                       wh2_preparation_form.quantity_return,  -- Fixed missing comma
                       wh2_preparation_form.area_location    -- Fixed missing comma
                FROM wh2_preparation_form
                INNER JOIN material_codes
                    ON wh2_preparation_form.material_code = material_codes.mid
                WHERE wh2_preparation_form.deleted = FALSE;
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
            background="white",  # Background color
            foreground="black",  # Font color
            font=("Arial", 30, "bold"),  # Font style and size
            anchor="center"  # Text alignment
        )

        # Title Label (with the custom style)
        label = ttk.Label(parent_frame, text="Warehouse 2: Preparation Form", style="Custom.TLabel")
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
                          lambda event: self.search_table(wh2_preparation_form, search_entry.get()))

        # Table Frame (with Scrollbar)
        table_frame = ttk.Frame(parent_frame)
        table_frame.grid(row=2, column=0, columnspan=3, padx=10, pady=10, sticky="nsew")

        scrollbar = ttk.Scrollbar(table_frame, orient="vertical")
        scrollbar.pack(side="right", fill="y")

        column_names_wh2_preparation_form = [
            "Reference No.", "Date Received", "Material Code", "Quantity Prepared", "Quantity Return", "Area Location"
        ]
        wh2_preparation_form = ttk.Treeview(
            table_frame,
            columns=column_names_wh2_preparation_form,
            show="headings",
            yscrollcommand=scrollbar.set,
            height=15
        )
        scrollbar.config(command=wh2_preparation_form.yview)

        for col_name in column_names_wh2_preparation_form:
            wh2_preparation_form.heading(col_name, text=col_name)
            wh2_preparation_form.column(col_name, width=150, anchor="center")
        wh2_preparation_form.pack(fill="both", expand=True)

        # Fetch data and populate the table
        data_wh2_preparation_form = self.fetch_data_from_wh2_preparation_form()
        self.update_treeview(wh2_preparation_form, data_wh2_preparation_form,
                             column_names_wh2_preparation_form)

        # Entry Fields
        entry_label = ttk.Label(parent_frame, text="Entry Fields", font=("Arial", 16, "bold"))
        entry_label.grid(row=3, column=0, columnspan=3, pady=10)

        entry_frame = ttk.Frame(parent_frame)
        entry_frame.grid(row=4, column=0, columnspan=3, pady=10)

        wh2_preparation_form_entries = []
        material_codes = self.fetch_material_codes()

        for i, label_text in enumerate(column_names_wh2_preparation_form):
            col_label = ttk.Label(entry_frame, text=label_text, font=("Arial", 12))
            col_label.grid(row=0, column=i, padx=10, pady=5)

            if label_text == "Date Received":
                date_entry = ttk.Entry(entry_frame, width=15)
                date_entry.grid(row=1, column=i, padx=10, pady=5)
                date_entry.bind("<KeyRelease>", format_date_input)  # Bind the formatting function
                wh2_preparation_form_entries.append(date_entry)
            elif label_text == "Material Code":
                def to_uppercase(*args):
                    combobox_var.set(combobox_var.get().upper())  # Convert input to uppercase

                combobox_var = tk.StringVar()
                combobox = ttk.Combobox(entry_frame, values=material_codes, width=15, textvariable=combobox_var)
                combobox.grid(row=1, column=i, padx=10, pady=5)

                # Bind trace function to enforce uppercase
                combobox_var.trace_add("write", to_uppercase)

                wh2_preparation_form_entries.append(combobox)
            else:
                entry = ttk.Entry(entry_frame, width=15)
                entry.grid(row=1, column=i, padx=10, pady=5)
                wh2_preparation_form_entries.append(entry)

        self.wh2_preparation_form_entries = wh2_preparation_form_entries

        # Buttons Frame
        button_frame = ttk.Frame(parent_frame)
        button_frame.grid(row=5, column=0, columnspan=3, pady=10)

        add_button = ttk.Button(
            button_frame,
            text="Add",
            command=lambda: self.add_row_wh2_preparation_form(wh2_preparation_form),
            width=10
        )
        add_button.grid(row=0, column=0, padx=5)

        update_button = ttk.Button(
            button_frame,
            text="Update",
            command=lambda: self.update_row_wh2_preparation_form(wh2_preparation_form),
            width=10
        )
        update_button.grid(row=0, column=1, padx=5)

        delete_button = ttk.Button(
            button_frame,
            text="Delete",
            command=lambda: self.delete_row_wh2_preparation_form(wh2_preparation_form),
            width=10
        )
        delete_button.grid(row=0, column=2, padx=5)

        clear_button = ttk.Button(
            button_frame,
            text="Clear",
            command=lambda: self.clear_row_wh2_preparation_form(wh2_preparation_form, clear_ui_only=True),
            width=10
        )
        clear_button.grid(row=0, column=3, padx=5)

        # Center Table, Labels, and Entry Fields
        parent_frame.grid_columnconfigure(0, weight=1)
        parent_frame.grid_rowconfigure(2, weight=1)

        entry_frame.grid_columnconfigure(0, weight=1)
        entry_frame.grid_columnconfigure(len(column_names_wh2_preparation_form) - 1, weight=1)

    def add_row_wh2_preparation_form(self, table):
        try:
            self.connect_db()  # Ensure the connection is open

            # Retrieve values from entry fields for Table 1
            reference_no = self.wh2_preparation_form_entries[0].get()
            date = self.wh2_preparation_form_entries[1].get()
            material_code = self.wh2_preparation_form_entries[2].get()
            quantity_prepared = self.wh2_preparation_form_entries[3].get()
            quantity_return = self.wh2_preparation_form_entries[4].get()
            area_location = self.wh2_preparation_form_entries[5].get()

            # Ensure inputs are not empty
            if not reference_no or not date or not material_code or not quantity_prepared or not quantity_return or not area_location:
                messagebox.showwarning("Missing Fields", "Please fill in all fields before adding.")
                return

            # Ensure quantity_return is a valid integer
            try:
                quantity_return = float(quantity_return)  # Convert to integer
            except ValueError:
                messagebox.showwarning("Invalid Input", "quantity_return must be a number.")
                return

            # Get material_code_id from the material_codes table
            get_material_id = "SELECT mid FROM material_codes WHERE material_code = %s"
            self.cursor.execute(get_material_id, (material_code,))
            material_code_id = self.cursor.fetchone()

            if material_code_id is None:
                messagebox.showerror("Error", f"Material code '{material_code}' not found in the database.")
                return

            material_code_id = material_code_id[0]  # Extract the ID from the tuple

            # Insert a new row into PostgreSQL (wh2_preparation_form table)
            query = """INSERT INTO wh2_preparation_form (reference_no, date, material_code, quantity_prepared, quantity_return, area_location) 
                       VALUES (%s, %s, %s, %s, %s, %s)"""
            values = (reference_no, date, material_code_id, quantity_prepared, quantity_return, f"Warehouse {area_location}")
            self.cursor.execute(query, values)
            self.conn.commit()

            messagebox.showinfo("Success", "Row added successfully to Table 1.")

            # After adding the row, refresh the Treeview to show the updated data
            data_wh2_preparation_form = self.fetch_data_from_wh2_preparation_form()
            self.update_treeview(table, data_wh2_preparation_form,
                                 ["Reference No.", "Date Received", "Material Code", "Quantity Prepared", "Quantity Return", "Area Location"])

        except Exception as e:
            messagebox.showerror("Error", f"Error while adding row to Table 1: {e}")
            self.conn.rollback()  # Rollback the transaction if there's an error
        finally:
            self.close_connection()

    def update_row_wh2_preparation_form(self, table):
        try:
            self.connect_db()  # Ensure the database connection is open

            # Get selected row from Treeview
            selected_item = table.selection()
            if not selected_item:
                messagebox.showwarning("No Selection", "Please select a row to update.")
                return

            # Extract reference_no from the selected row (assuming it's the first column)
            selected_values = table.item(selected_item, "values")
            reference_no = selected_values[0].strip() if selected_values else None

            if not reference_no:
                messagebox.showerror("Error", "Failed to get Reference No. from the selected row.")
                return

            # Fetch the row's ID using reference_no
            self.cursor.execute("SELECT id FROM wh2_preparation_form WHERE reference_no = %s", (reference_no,))
            result = self.cursor.fetchone()

            if not result:
                messagebox.showerror("Error",
                                     "No matching record found in the database for the selected reference number.")
                return

            row_id = result[0]  # Extract the ID

            # Retrieve values from entry fields (only update non-empty fields)
            date = self.wh2_preparation_form_entries[1].get().strip()
            material_code = self.wh2_preparation_form_entries[2].get().strip()
            quantity_prepared = self.wh2_preparation_form_entries[3].get().strip()
            quantity_return = self.wh2_preparation_form_entries[4].get().strip()
            area_location = self.wh2_preparation_form_entries[5].get().strip()

            # Get material_code_id from material_codes table (if material_code is provided)
            material_code_id = None
            if material_code:
                self.cursor.execute("SELECT mid FROM wh2_material_codes WHERE material_code = %s", (material_code,))
                result = self.cursor.fetchone()
                if result:
                    material_code_id = result[0]  # Extract the integer ID

            # Build the update query dynamically based on non-empty fields
            query = "UPDATE wh2_preparation_form SET "
            values = []

            if date:
                query += "date = %s, "
                values.append(date)
            if material_code_id:
                query += "material_code = %s, "
                values.append(material_code_id)
            if quantity_prepared:
                query += "quantity_prepared = %s, "
                values.append(float(quantity_prepared))  # Convert to float
            if quantity_return:
                query += "quantity_return = %s, "
                values.append(float(quantity_return))  # Convert to float
            if area_location:
                query += "area_location = %s, "
                values.append(area_location)

            # Ensure at least one field is being updated
            if not values:
                messagebox.showwarning("No Changes", "No new values provided to update.")
                return

            # Remove trailing comma and space
            query = query.rstrip(", ")

            # Add WHERE clause to update only the selected row based on ID
            query += " WHERE id = %s"
            values.append(row_id)  # Use the fetched ID

            # Execute the update query
            self.cursor.execute(query, tuple(values))
            self.conn.commit()

            messagebox.showinfo("Success", "Selected row updated successfully.")

            # Refresh the Treeview to reflect the changes
            updated_data = self.fetch_data_from_wh2_preparation_form()
            self.update_treeview(table, updated_data,
                                 ["Reference No.", "Date", "Material Code", "Quantity Prepared", "Quantity Return",
                                  "Area Location"])

        except Exception as e:
            messagebox.showerror("Error", f"Error while updating the row: {e}")
            self.conn.rollback()  # Rollback in case of an error
        finally:
            self.close_connection()

    def delete_row_wh2_preparation_form(self, table):
        """Permanently delete the selected row using its unique 'id' fetched from PostgreSQL."""
        try:
            self.connect_db()  # Ensure the database connection is open

            # Get selected row from Treeview
            selected_item = table.selection()
            if not selected_item:
                messagebox.showwarning("No Selection", "Please select a row to delete.")
                return

            # Extract row values from Treeview
            row_values = table.item(selected_item, "values")
            print("Row values:", row_values)  # Debugging step to check values

            if not row_values:
                messagebox.showerror("Error", "No row data found. Please try again.")
                return

            # Extract reference_no and displayed material_code from Treeview
            reference_no = row_values[0]  # Reference Number
            material_code_str = row_values[2]  # Material Code (as displayed in Treeview)

            # Fetch the actual 'mid' (integer) from the material_codes table
            query = "SELECT mid FROM wh2_material_codes WHERE material_code = %s LIMIT 1;"
            self.cursor.execute(query, (material_code_str,))
            result = self.cursor.fetchone()

            if not result:
                messagebox.showerror("Error", f"No matching material code '{material_code_str}' found in database.")
                return

            material_code = result[0]  # Get the integer 'mid'

            # Fetch the unique 'id' from wh1_receiving_report
            query = "SELECT id FROM wh2_preparation_form WHERE reference_no = %s AND material_code = %s LIMIT 1;"
            self.cursor.execute(query, (reference_no, material_code))
            result = self.cursor.fetchone()

            if not result:
                messagebox.showerror("Error", "No matching record found in the database.")
                return

            row_id = result[0]  # Extract the actual ID from the query result

            # Confirm deletion
            confirm = messagebox.askyesno("Confirm Deletion",
                                          f"Are you sure you want to permanently delete row ID {row_id}?")
            if not confirm:
                return

            # Perform hard delete (permanent)
            query = "DELETE FROM wh2_preparation_form WHERE id = %s;"
            self.cursor.execute(query, (row_id,))
            self.conn.commit()

            # Remove the row from the Treeview
            table.delete(selected_item)

            messagebox.showinfo("Success", f"Row ID {row_id} permanently deleted.")

        except Exception as e:
            messagebox.showerror("Error", f"Error while deleting row: {e}")
            print("Error while deleting row:", e)
            self.conn.rollback()
        finally:
            self.close_connection()

    def clear_row_wh2_preparation_form(self, table, clear_ui_only=True):
        """
        Mark all rows as deleted (flagging rows in the UI and database).
        The `clear_ui_only` flag determines if only the UI should be cleared or if other actions are required.
        """
        try:
            # Confirm if the user wants to clear all rows from the UI
            confirm = messagebox.askyesno("Confirm Clear", "Are you sure you want to mark all rows as deleted?")
            if not confirm:
                return

            if clear_ui_only:
                # Clear all rows from the Treeview (UI)
                table.delete(*table.get_children())  # This removes all the rows in the table.
                messagebox.showinfo("Success", "All rows have been cleared from the table (UI only).")

                # Mark rows as deleted in the database
                query = "UPDATE wh2_preparation_form SET deleted = TRUE WHERE deleted = FALSE;"
                self.cursor.execute(query)
                self.conn.commit()
                messagebox.showinfo("Database Update", "All rows have been marked as deleted in the database.")
            else:
                # Add any other action here based on the flag if needed
                messagebox.showinfo("Action",
                                    "Flag set to False, performing another action (can be clearing DB or anything).")

        except Exception as e:
            messagebox.showerror("Error", f"Error while clearing rows: {e}")
            self.conn.rollback()  # Rollback the transaction if there's an error

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
            SELECT 
                wpf.reference_no, 
                TO_CHAR(wpf.date, 'MM/DD/YYYY') AS date, 
                mc.material_code, 
                wpf.quantity_prepared, 
                wpf.quantity_return, 
                wpf.area_location 
            FROM wh2_preparation_form wpf
            JOIN wh2_material_codes mc ON wpf.material_code = mc.mid  -- Ensure 'mid' is the correct key
            WHERE wpf.reference_no::TEXT ILIKE %s OR mc.material_code::TEXT ILIKE %s;
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
