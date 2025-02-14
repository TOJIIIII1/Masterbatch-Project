import tkinter as tk
import psycopg2
from tkinter import ttk, messagebox

class Spreadsheet2:
    def __init__(self):
        self.conn = None
        self.cursor = None
        self.data = []  # Data for the table
        self.current_page = 1
        self.rows_per_page = 20  # Number of rows to display per page
        self.connect_to_db()

    def connect_to_db(self):
        """Connect to the PostgreSQL database."""
        try:
            self.conn = psycopg2.connect(
                host="192.168.1.13",  # Replace with your database host
                port=5432,  # Replace with your database port
                dbname="Inventory",  # Replace with your database name
                user="postgres",  # Replace with your username
                password="mbpi"  # Replace with your password
            )
            self.cursor = self.conn.cursor()
            self.load_data_from_db()  # Load data after connecting
        except Exception as e:
            messagebox.showerror("Error", f"Failed to connect to the database: {e}")

    def load_data_from_db(self):
        """Fetch data from PostgreSQL, retrieve material_code_id, and load it into the table."""
        try:
            query = """
            SELECT
                m.material_code,   
                COALESCE(mt.total_quantity, 0) AS quantity,   
                COALESCE(m.qty_per_packing, 0) AS qty_per_packing,
                -- Set whse1_excess to 0
                0 AS whse1_excess,
                COALESCE(mt.status, 'Good') AS status -- Get status from wh2_material_code_totals
            FROM 
                wh2_material_codes AS m
            LEFT JOIN 
                wh2_material_code_totals AS mt ON m.mid = mt.ID
            LEFT JOIN 
                wh2_transfer_form AS wtf ON m.mid = wtf.material_code
            LEFT JOIN 
                wh2_receiving_report AS wrr ON m.mid = wrr.material_code
            GROUP BY 
                m.material_code, mt.total_quantity, m.qty_per_packing, mt.status
            HAVING 
                mt.total_quantity > 0
            ORDER BY 
                m.material_code, status ASC;

            """

            self.cursor.execute(query)
            rows = self.cursor.fetchall()

            # Process the fetched rows and store them in self.data
            self.process_fetched_data(rows)

        except Exception as e:
            messagebox.showerror("Error", f"Failed to fetch and update data: {e}")
            print("Error", f"Failed to fetch and update data: {e}")
            self.conn.rollback()  # Rollback in case of error

    def process_fetched_data(self, rows):
        """Process the fetched data and populate self.data."""
        try:
            self.data = []
            for row in rows:
                material_code = row[0]  # Fetch material_code directly
                no_of_bags = row[1]
                qty_per_packing = row[2]
                whse1_excess = row[3]
                status = row[4]  # Fetch the status

                # Ensure no_of_bags and qty_per_packing are converted to float (double precision)
                try:
                    no_of_bags = float(no_of_bags) if no_of_bags is not None else 0.0
                    qty_per_packing = float(qty_per_packing) if qty_per_packing is not None else 0.0
                    whse1_excess = float(whse1_excess) if whse1_excess is not None else 0.0
                except (ValueError, TypeError):  # Catch invalid types and values
                    no_of_bags = 0.0  # Default to 0.0 if conversion fails
                    qty_per_packing = 0.0  # Default to 0.0 if conversion fails
                    whse1_excess = 0.0

                # Calculate Total (Number of Bags * Quantity per Packing)
                total = no_of_bags + whse1_excess

                # Ensure total is a double precision (float)
                total = float(total)

                # Ensure material_code is always treated as a string (even if it's alphanumeric)
                material_code = str(material_code).strip()

                self.data.append(
                    (material_code, no_of_bags, qty_per_packing, whse1_excess, total, status)
                )

            # After processing, update or insert the data into the `wh2_spreadsheet` table
            self.update_or_insert_data_into_spreadsheet()

        except Exception as e:
            messagebox.showerror("Error", f"Failed to process fetched data: {e}")
            self.conn.rollback()  # Rollback in case of error

    def update_or_insert_data_into_spreadsheet(self):
        """Update or insert data into the wh2_spreadsheet table."""
        try:
            for record in self.data:
                material_code, quantity, qty_per_packing, whse1_excess, total, status = record

                # Ensure whse1_excess is a float (double precision)
                try:
                    whse1_excess = float(whse1_excess) if whse1_excess is not None else 0.0
                except (ValueError, TypeError):  # Catch invalid types and values
                    whse1_excess = 0.0  # Default to 0.0 if conversion fails

                # Check if the record exists in the `wh2_spreadsheet` table
                check_query = """
                SELECT 1 FROM wh2_spreadsheet 
                WHERE material_code = %s;
                """
                self.cursor.execute(check_query, (material_code,))
                existing_record = self.cursor.fetchone()

                if existing_record:  # Record exists, perform an update
                    update_query = """
                    UPDATE wh2_spreadsheet
                    SET no_of_bags = %s, qty_per_packing = %s, whse1_excess = %s, total = %s, status = %s
                    WHERE material_code = %s;
                    """
                    values = (
                        float(quantity), float(qty_per_packing), float(whse1_excess), float(total), status,
                        material_code
                    )
                    print(f"Updating record for material_code: {material_code}")
                    self.cursor.execute(update_query, values)
                else:  # Record does not exist, insert a new row
                    insert_query = """
                    INSERT INTO wh2_spreadsheet (material_code, no_of_bags, qty_per_packing, whse1_excess, total, status)
                    VALUES (%s, %s, %s, %s, %s, %s);
                    """
                    values = (
                        material_code, float(quantity), float(qty_per_packing), float(whse1_excess),
                        float(total), status
                    )
                    print(f"Inserting new record for material_code: {material_code}")
                    self.cursor.execute(insert_query, values)

            # Commit the transaction after all updates and inserts
            self.conn.commit()

        except Exception as e:
            print(f"Error during insert/update: {e}")
            self.conn.rollback()  # Rollback in case of error

    def display(self, parent_frame):
        """Display the Export Table page with a properly sized table and search bar."""

        # Clear existing widgets in the parent frame
        for widget in parent_frame.winfo_children():
            widget.destroy()

        # Configure the parent frame to be expandable
        parent_frame.grid_rowconfigure(0, weight=1)
        parent_frame.grid_columnconfigure(0, weight=1)

        # Create a frame to hold everything
        frame = ttk.Frame(parent_frame)
        frame.grid(row=0, column=0, sticky="nsew")

        # **Ensure the table gets enough space**
        frame.grid_rowconfigure(2, weight=1)  # Table should take up most space
        frame.grid_columnconfigure(0, weight=1)

        # **Move Header to the Top**
        tk.Label(frame, text="SOH SUMMARY", font=("Arial", 25, "bold")).grid(
            row=0, column=0, padx=10, pady=(10, 5), columnspan=5
        )

        # Search Bar Below Header
        search_frame = ttk.Frame(frame)
        search_frame.grid(row=1, column=0, columnspan=5, pady=(5, 5), sticky="ew")  # Keeps layout clean

        tk.Label(search_frame, text="Search:", font=("Arial", 12)).pack(side="left", padx=5)

        # **Limit Search Bar Width**
        search_entry = ttk.Entry(search_frame, width=30)  # Set a fixed width (adjust as needed)
        search_entry.pack(side="left", padx=5)

        def search():
            """Filter Treeview based on search query across all data."""
            query = search_entry.get().strip().lower()

            # Clear existing table content
            for row in self.tree.get_children():
                self.tree.delete(row)

            # Filter self.data to match the query
            filtered_data = [row for row in self.data if query in str(row[0]).lower()]  # Searching in "Material Code"

            # Display filtered data (ignoring pagination for now)
            for row in filtered_data:
                self.tree.insert("", tk.END, values=row)

            # Reset pagination label (optional)
            self.page_label.config(text="Search Results" if query else f"Page {self.current_page}")

            # If search is cleared, reload paginated data
            if not query:
                self.load_data()

        search_entry.bind("<KeyRelease>", lambda event: search())

        # Create a frame to hold the table and scrollbars
        table_frame = ttk.Frame(frame, padding=(20, 10))  # Adds left & right margin
        table_frame.grid(row=2, column=0, columnspan=5, sticky="nsew")

        # Allow frame to expand dynamically
        frame.grid_rowconfigure(2, weight=1)  # Ensures table takes most space
        frame.grid_columnconfigure(0, weight=1)  # Expands width as needed

        # **Treeview for displaying data**
        self.tree = ttk.Treeview(
            table_frame,
            columns=("Material Code", "Number of Bags", "Quantity per Packing", "WHSE #1 - Excess", "Total", "Status"),
            show="headings",
        )

        # Define column headings
        self.tree.heading("Material Code", text="Material Code")
        self.tree.heading("Number of Bags", text="Number of Bags")
        self.tree.heading("Quantity per Packing", text="Quantity per Packing")
        self.tree.heading("WHSE #1 - Excess", text="WHSE #1 - Excess")
        self.tree.heading("Total", text="Total")
        self.tree.heading("Status", text="Status")

        # Set column widths and alignment
        self.tree.column("Material Code", width=150, anchor="center", stretch=True)
        self.tree.column("Number of Bags", width=150, anchor="center", stretch=True)
        self.tree.column("Quantity per Packing", width=180, anchor="center", stretch=True)
        self.tree.column("WHSE #1 - Excess", width=180, anchor="center", stretch=True)
        self.tree.column("Total", width=150, anchor="center", stretch=True)
        self.tree.column("Status", width=150, anchor="center", stretch=True)

        # Scrollbars - Inside `table_frame` for proper alignment
        tree_scroll_y = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        tree_scroll_x = ttk.Scrollbar(table_frame, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=tree_scroll_y.set, xscrollcommand=tree_scroll_x.set)

        # **Positioning the Table Properly**
        self.tree.grid(row=0, column=0, sticky="nsew")
        tree_scroll_y.grid(row=0, column=1, sticky="ns")
        tree_scroll_x.grid(row=1, column=0, sticky="ew")

        # Ensure table expands properly within its frame
        table_frame.grid_rowconfigure(0, weight=1)
        table_frame.grid_columnconfigure(0, weight=1)

        # **Pagination Controls - Centered**
        pagination_frame = ttk.Frame(frame)
        pagination_frame.grid(row=3, column=0, columnspan=5, pady=(5, 5))

        prev_button = ttk.Button(pagination_frame, text="Previous", command=self.prev_page)
        prev_button.pack(side="left", padx=10)

        self.page_label = ttk.Label(pagination_frame, text=f"Page {self.current_page}", font=("Arial", 12, "bold"))
        self.page_label.pack(side="left", padx=10)  # Centered between buttons

        next_button = ttk.Button(pagination_frame, text="Next", command=self.next_page)
        next_button.pack(side="left", padx=10)

        self.refresh_table()  # Load data into the Treeview

    def refresh_table(self):
        """Refresh the data in the Treeview."""
        self.load_data_from_db()  # Reload the data from the database
        self.load_data()

    def load_data(self):
        """Load data into the Treeview with row highlights."""
        # Clear existing data in the Treeview
        for row in self.tree.get_children():
            self.tree.delete(row)

        # Define colors for row highlighting
        self.tree.tag_configure("evenrow", background="black")  # Light gray
        self.tree.tag_configure("oddrow", background="black")  # White (default)

        # Calculate the start and end indices for the current page
        start_index = (self.current_page - 1) * self.rows_per_page
        end_index = start_index + self.rows_per_page

        # Insert new data into the Treeview for the current page
        for index, row in enumerate(self.data[start_index:end_index]):
            tag = "evenrow" if index % 2 == 0 else "oddrow"
            self.tree.insert("", tk.END, values=row, tags=(tag,))

        # Update the page label
        self.page_label.config(text=f"Page {self.current_page}")

    def prev_page(self):
        """Navigate to the previous page."""
        if self.current_page > 1:
            self.current_page -= 1
            self.load_data()

    def next_page(self):
        """Navigate to the next page."""
        if self.current_page * self.rows_per_page < len(self.data):
            self.current_page += 1
            self.load_data()  # Load the new page

