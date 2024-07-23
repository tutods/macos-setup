import inquirer
import subprocess
import os
from inquirer.themes import GreenPassion

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))

# Function to get the Python command based on the macOS version
def get_python_command():
    return 'python3' if platform.system() == 'Darwin' and int(platform.release().split('.')[0]) >= 20 else 'python'


# List of options to print and respective shell script to run
options = {
    'Use FNM': 'fnm.sh',
    'Use ASDF': 'asdf.sh',
}

global_packages_options = {
    "Commitizen": "commitizen",
    "NPM Check": "npm-check",
    "Lerna": "lerna"
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

    # Install node manager
    node_manager = answers["node-version-manager"]
    if node_manager:
        node_manager_cmd = options.get(node_manager)

        if node_manager_cmd.endswith('.py'):
            subprocess.run([get_python_command(), node_manager_cmd])
        else:
            subprocess.run(['sh', node_manager_cmd], cwd=current_dir)

    else:
        print("No command for {node_manager}")

    # Install NPM global packages
    global_packages = answers["global-packages"]
    if len(global_packages) != 0:
        print("Installing global NPM packages")

        selected_values = [global_packages_options[key] for key in global_packages]
        joined_values = ' '.join(selected_values)

        subprocess.run(f"npm i -g {joined_values}",
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True)

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
