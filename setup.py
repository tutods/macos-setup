import inquirer
import subprocess
import platform


# Function to get the Python command based on the macOS version
def get_python_command():
    return 'python3' if platform.system() == 'Darwin' and int(platform.release().split('.')[0]) >= 20 else 'python'


# List of options to print and respective shell script to run
options = {
    'Homebrew': 'sh ./homebrew/setup.sh',
    'Shell (using Fish)': 'fish/setup.py',
    'VSCode': 'sh ./vscode/setup.sh',
    'Hyper': 'sh ./hyper/setup.sh'
}

questions = [
    inquirer.Checkbox(
        "options",
        message="Which steps you want to execute to setup your macOS?",
        choices=list(options.keys()),
    ),
]

answers = inquirer.prompt(questions)
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
            print("PY")
            subprocess.run([get_python_command(), command])
        else:
            process = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                     text=True)
            print(process.stdout)
    else:
        print("No command for {option}")
