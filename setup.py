import inquirer
import subprocess

# List of options to print and respective shell script to run
options = {
    'Homebrew': 'sh ./homebrew/setup.sh',
    'Shell (using Fish)': 'sh ./fish/setup.sh',
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
        print(command)
        output = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True)
        print(output.stdout)
    else:
        print("No command for {option}")
