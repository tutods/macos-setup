import inquirer
import subprocess
import os
from inquirer.themes import GreenPassion

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(current_dir)

# Function to get the Python command based on the macOS version
def get_python_command():
    return 'python3' if platform.system() == 'Darwin' and int(platform.release().split('.')[0]) >= 20 else 'python'

# Get all casks from file
with open('configs/casks.txt', 'r') as file:
    options = file.readlines()
    casks_options = [option.strip() for option in options]

# Get all formulaes from file
with open('configs/formulaes.txt', 'r') as file:
    options = file.readlines()
    formulaes_options = [option.strip() for option in options]

try:
    questions = [
        inquirer.Confirm("install", message="Do you want to install homebrew?"),
        inquirer.Checkbox(
            "casks",
            message="Which casks you want to install?",
            choices=list(casks_options),
        ),
        inquirer.Checkbox(
            "formulaes",
            message="Which formulaes you want to install?",
            choices=list(formulaes_options),
        ),
    ]
    answers = inquirer.prompt(questions, theme=GreenPassion())

    if answers is None:
        print("No answers to proceed!")
    else:
        # Install Homebrew
        install_brew = answers["install"]
        if answers["install"]:
            print("1) Installing Homebrew...")
            install_result = subprocess.run(['sh', 'scripts/install.sh'],
                check=True)

        # Install casks
        casks_to_install = answers["casks"]
        if len(casks_to_install) != 0:
            print("2) Installing selected casks")
            joined_values = ' '.join(casks_to_install)

            casks_result = subprocess.run(f"brew install --force --cask {joined_values}",
                shell=True,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True)

            print(casks_result.stdout)

        formulaes_to_install = answers["formulaes"]
        if len(formulaes_to_install) != 0:
            print("3) Installing selected formulaes")
            joined_values = ' '.join(formulaes_to_install)

            if "consize" in formulaes_to_install:
                subprocess.run(f"brew tap shinokada/consize",
                    shell=True,
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True)

            formulaes_result = subprocess.run(f"brew install --force {joined_values}",
                shell=True,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True)

            print(formulaes_result.stdout)

except subprocess.CalledProcessError as e:
  # Handle the error here
  print(f"An error occurred: {e}")
  # Stop the execution or raise an exception to halt the script
  raise SystemExit(1)  # Exit the script with an error code

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
