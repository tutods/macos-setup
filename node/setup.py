import inquirer
import subprocess
import os
import platform
from inquirer.themes import GreenPassion

# Function to get the Python command based on the macOS version
def get_python_command():
    return 'python3' if platform.system() == 'Darwin' and int(platform.release().split('.')[0]) >= 20 else 'python'

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(current_dir)

global_packages_options = {}

with open('configs/packages.txt', 'r') as file:
    for line in file:
        package, command = line.strip().split(':')
        global_packages_options[package.strip()] = command.strip()

# List of options to print and respective shell script to run
options = {
    'Use FNM': 'scripts/fnm.sh',
    'Use ASDF': 'scripts/asdf.sh',
}

try:
    questions = [
        inquirer.List("node-version-manager", message="Which node version manager you want to use?",
                      choices=list(options.keys()),
                      default="Use FNM"
                      ),
        inquirer.Checkbox(
            "global-packages",
            message="Which global packages you want to install?",
            choices=list(global_packages_options.keys()),
            default=["NPM Check"],
        ),
    ]
    answers = inquirer.prompt(questions, theme=GreenPassion())

    if answers is None:
        print("No answers to proceed!")
    else:
        # Install node manager
        node_manager = answers["node-version-manager"]
        if node_manager:
            node_manager_cmd = options.get(node_manager)
            print(node_manager_cmd)
            subprocess.run(f"sh {node_manager_cmd}", check=True, cwd=current_dir)
        else:
            print("No command for {node_manager}")
        # Install NPM global packages
        global_packages = answers["global-packages"]
        if len(global_packages) != 0:
            print("Installing global NPM packages")

            selected_values = [global_packages_options[key] for key in global_packages]
            joined_values = ' '.join(selected_values)

            subprocess.run(f"npm i -g {joined_values}", check=True, shell=True)

except subprocess.CalledProcessError as e:
  # Handle the error here
  print(f"An error occurred: {e}")
  # Stop the execution or raise an exception to halt the script
  raise SystemExit(1)  # Exit the script with an error code

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
