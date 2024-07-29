import inquirer
import subprocess
import os
from inquirer.themes import GreenPassion

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))

try:
    questions = [
        inquirer.Confirm("install", message="Do you want to install Starship theme?", default=True),
        inquirer.List(
            "theme",
            message="Which color schema do you want to use?",
            choices=[
                ("None", "none"),
                ("Dracula colors", "dracula"),
                ("Default colors (defined by the terminal)", "terminal"),
            ],
            default=["none"]
        )
    ]
    answers = inquirer.prompt(questions, theme=GreenPassion())

    if answers is None:
        print("No answers to proceed!")
    else:
        if answers["install"]:
            print("1) Installing Starship...")
            subprocess.run(['sh', 'scripts/install.sh'],
                check=True, cwd=current_dir)

        if answers["theme"] == "dracula":
            print("4) Configuring Starship colors...")
            subprocess.run(['sh', 'scripts/dracula-theme.sh'], check=True, cwd=current_dir)
        
        if answers["theme"] == "terminal":
            print("4) Configuring Starship colors...")
            subprocess.run(['sh', 'scripts/default-theme.sh'], check=True, cwd=current_dir)
            
except subprocess.CalledProcessError as e:
  # Handle the error here
  print(f"An error occurred: {e}")
  # Stop the execution or raise an exception to halt the script
  raise SystemExit(1)  # Exit the script with an error code

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
