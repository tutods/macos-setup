import inquirer
from pprint import pprint
import subprocess

options = {
  'Homebrew': 'sh ./homebrew/setup.sh',
  'Shell': 'sh ./shell/setup.sh',
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

for option in selected_options:
  command = options.get(option)
  
  if command:
    print(command)
    output = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    print(output.stdout)
  else:
    print("No command for {option}")
  