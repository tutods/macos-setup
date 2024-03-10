import shutil
import os
import getpass

# Get the current user's home directory
user_dir = os.path.expanduser("~")

# Path to the file you want to copy
file_to_copy = 'path_to_your_file_to_copy'

# Destination path in the user's directory
destination_path = os.path.join(user_dir, 'destination_folder', 'new_file_name')

# Copy the file to the user's directory
shutil.copy(file_to_copy, destination_path)

print(f"File copied to {destination_path}")
