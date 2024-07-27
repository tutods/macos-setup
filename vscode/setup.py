import inquirer
import subprocess
import os
import platform
from inquirer.themes import GreenPassion

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(current_dir)

# Get all casks from file
with open('configs/extensions.txt', 'r') as file:
    options = file.readlines()
    extensions = [option.strip() for option in options]

try:
    questions = [
        inquirer.Confirm("install", message="Do you want to install Visual Studio Code?", default=True),
        inquirer.Confirm("config", message="Do you want to copy my configuration?", default=True),
        inquirer.Checkbox(
            "extensions",
            message="Which casks you want to install?",
            choices=list(extensions),
            default=list(extensions)
        ),
    ]
    answers = inquirer.prompt(questions, theme=GreenPassion())

    if answers is None:
        print("No answers to proceed!")
    else:
        # Install Homebrew
        if answers["install"]:
            print("1) Installing Visual Studio Code...")
            subprocess.run(['sh', 'scripts/install.sh'],
                check=True)

        if answers["config"]:
            print("2) Copying configuration...")
            subprocess.run(['sh', 'scripts/config.sh'],
                check=True, cwd=current_dir)

        # Install casks
        extensions_to_install = answers["extensions"]
        if len(extensions_to_install) != 0:
            print("3) Installing extensions...")

            for extension in extensions_to_install:
                subprocess.run(f"code --install-extension {extension} --force", check=True, shell=True)

except subprocess.CalledProcessError as e:
  # Handle the error here
  print(f"An error occurred: {e}")
  # Stop the execution or raise an exception to halt the script
  raise SystemExit(1)  # Exit the script with an error code

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
