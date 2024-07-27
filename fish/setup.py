import inquirer
import subprocess
import os
from inquirer.themes import GreenPassion

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))

try:
    questions = [
        inquirer.Confirm("install", message="Do you want to install fish?", default=True),
        inquirer.Confirm(
            "configs",
            message="Do you want to copy the fish configurations?",
            default=True,
        ),
        inquirer.Confirm(
            "fisher",
            message="Do you want to install fisher to manage fish plugins?",
            default=True,
        ),
    ]
    answers = inquirer.prompt(questions, theme=GreenPassion())

    if answers is None:
        print("No answers to proceed!")
    else:
        # Install Homebrew
        if answers["install"]:
            print("1) Installing Fish...")
            subprocess.run(['sh', 'scripts/install.sh'],
                check=True)

        if answers["configs"]:
            print("2) Copying configurations...")
            subprocess.run(['sh', 'scripts/config.sh'],
                check=True)

        if answers["fisher"]:
            print("3) Installing and configuring fisher...")
            subprocess.run(['sh', 'scripts/fisher.sh'],
                check=True)

except subprocess.CalledProcessError as e:
  # Handle the error here
  print(f"An error occurred: {e}")
  # Stop the execution or raise an exception to halt the script
  raise SystemExit(1)  # Exit the script with an error code

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
