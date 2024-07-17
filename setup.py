import inquirer
import subprocess
import platform


# Function to get the Python command based on the macOS version
def get_python_command():
    return 'python3' if platform.system() == 'Darwin' and int(platform.release().split('.')[0]) >= 20 else 'python'


# List of options to print and respective shell script to run
options = {
    'Homebrew': 'homebrew/setup.sh',
    'Shell (using Fish)': 'fish/setup.py',
    'Node.js': 'node/setup.py',
    'VSCode': 'sh ./vscode/setup.sh',
    'Hyper': 'sh ./hyper/setup.sh'
}

try:
    questions = [
        inquirer.Checkbox(
            "options",
            message="Which steps you want to execute to setup your macOS?",
            choices=list(options.keys()),
        ),
    ]
    answers = inquirer.prompt(questions)

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
                    subprocess.run(['sh', command], shell=True, check=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True)
            else:
                print("No command for {option}")
except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
