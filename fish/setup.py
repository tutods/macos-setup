import inquirer
import subprocess
import os

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))

# List of options to print and respective shell script to run
options = {
    'Install': 'sh scripts/install.sh',
    'Copy config.': 'sh scripts/config.sh',
    'Oh-my-fish': 'sh scripts/omf.sh',
}

questions = [
    inquirer.Checkbox(
        "options",
        message="Which steps you want to execute to setup your shell using Fish",
        choices=list(options.keys()),
        default=["Install", "Copy config.", "Oh-my-fish"]
    ),
]

answers = inquirer.prompt(questions)
selected_options = answers['options']

# If the user don't have any selected option, don't run any script
if len(selected_options) == 0:
    print("No selected options!")
    exit(-1)

# print(os.getcwd())

# Loop on selected options
for option in selected_options:
    script_to_run = options.get(option)
    print(current_dir, script_to_run)

    if script_to_run:
        print("👉 Running:", option)
        process = subprocess.run(script_to_run, shell=True, check=True, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE,
                                 text=True, cwd=current_dir)
        print(process.stdout)
    else:
        print("No command for {option}")
