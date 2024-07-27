import inquirer
import subprocess
import os
from inquirer.themes import GreenPassion

# Get the path for this file
current_dir = os.path.dirname(os.path.abspath(__file__))

# List of options to print and respective shell script to run
options = {
    'Install': 'scripts/install.sh',
    'Copy config.': 'scripts/config.sh',
    'Oh-my-fish': 'scripts/omf.sh',
}

try:
    questions = [
        inquirer.Checkbox(
            "options",
            message="Which steps you want to execute to setup your shell using Fish",
            choices=list(options.keys()),
            default=["Install", "Copy config.", "Oh-my-fish"]
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
            script_to_run = options.get(option)
            print(current_dir, script_to_run)

            if script_to_run:
                print("👉 Running:", option)
                subprocess.run(["sh", script_to_run], shell=True,
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    cwd=current_dir)
            else:
                print("No command for {option}")

except subprocess.CalledProcessError as e:
  # Handle the error here
  print(f"An error occurred: {e}")
  # Stop the execution or raise an exception to halt the script
  raise SystemExit(1)  # Exit the script with an error code

except KeyboardInterrupt:
    print("CTRL+C pressed. Exiting... 👋")
