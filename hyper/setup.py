import inquirer
import subprocess
import os
from inquirer.themes import GreenPassion

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))

try:
    questions = [
        inquirer.Confirm("install", message="Do you want to install Hyper terminal?", default=True),
        inquirer.Confirm("config", message="Do you want to copy Hyper terminal config?", default=True),
        inquirer.Confirm("plugins", message="Do you want to install the Hyper terminal plugins?", default=True),
    ]
    answers = inquirer.prompt(questions, theme=GreenPassion())

    if answers is None:
        print("No answers to proceed!")
    else:
        if answers["install"]:
            print("1) Installing Hyper terminal...")
            subprocess.run(['sh', 'scripts/install.sh'],
                check=True, cwd=current_dir)
        
        if answers["config"]:
            print("2) Copying Hyper terminal config...")
            subprocess.run(['sh', 'scripts/config.sh'],
                check=True, cwd=current_dir)
        
        if answers["plugins"]:
            print("3) Installing Hyper terminal plugins...")
            subprocess.run(['sh', 'scripts/plugins.sh'],
                check=True, cwd=current_dir)
            
except subprocess.CalledProcessError as e:
  # Handle the error here
  print(f"An error occurred: {e}")
  # Stop the execution or raise an exception to halt the script
  raise SystemExit(1)  # Exit the script with an error code

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
