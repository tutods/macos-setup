import inquirer
import subprocess
import platform
from inquirer.themes import GreenPassion

# Function to get the Python command based on the macOS version
def get_python_command():
    return 'python3' if platform.system() == 'Darwin' and int(platform.release().split('.')[0]) >= 20 else 'python'


# List of options to print and respective shell script to run
options = {
    'Homebrew': 'homebrew/setup.py',
    'Shell (using Fish)': 'fish/setup.py',
    'Starship theme': 'starship/setup.py',
    'Node.js': 'node/setup.py',
    'VSCode': 'vscode/setup.py',
    'Hyper': 'hyper/setup.py',
}

try:
    questions = [
        inquirer.Checkbox(
            "options",
            message="Which steps you want to execute to setup your macOS?",
            choices=list(options.keys()),
        ),
    ]
    answers = inquirer.prompt(questions, theme=GreenPassion())

    if answers and 'options' in answers:
        selected_options = answers['options']

        # If the user don't have any selected option, don't run any script
        if len(selected_options) == 0:
            print("No selected options!")
            exit(-1)

        # Loop on selected options
        for option in selected_options:
            command = options.get(option)

            if command:
                if command.endswith('.py'):
                    subprocess.run([get_python_command(), command])
                else:
                    subprocess.run(['sh', command])
            else:
                print("No command for {option}")
except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
