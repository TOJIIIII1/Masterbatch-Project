

def format_date_input(event):
    """Format date as MM/DD/YYYY while the user types."""
    entry = event.widget
    date_text = entry.get().replace("/", "")  # Remove existing slashes
    formatted_date = ""
    original_cursor_pos = entry.index("insert")  # Save original cursor position before formatting
    num_slashes_before = entry.get().count("/")  # Count slashes before formatting

    # Format the input step by step
    if len(date_text) > 0:
        formatted_date += date_text[:2]  # Add MM
    if len(date_text) > 2:
        formatted_date += "/" + date_text[2:4]  # Add DD
    if len(date_text) > 4:
        formatted_date += "/" + date_text[4:8]  # Add YYYY

    # Prevent accidental deletion of text
    entry.delete(0, "end")
    entry.insert(0, formatted_date[:10])  # Limit to MM/DD/YYYY

    # Adjust cursor position to account for slashes
    num_slashes_after = formatted_date.count("/")
    cursor_shift = num_slashes_after - num_slashes_before
    new_cursor_pos = original_cursor_pos + cursor_shift

    # Ensure cursor position is within bounds
    new_cursor_pos = min(new_cursor_pos, len(formatted_date))
    entry.icursor(new_cursor_pos)