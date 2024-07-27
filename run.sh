#!/bin/bash

# Create Python virtual environment
if command -v python3 &> /dev/null; then
    python3 -m venv env # using Python 3.x
elif command -v python &> /dev/null; then
    python -m venv env # using Python 2.x
else
    echo "Python is not installed. Please install Python."
fi

# Active the virtual environment
source env/bin/activate

# Install pipenv
if command -v python3 &> /dev/null; then
    python3 -m pip install inquirer # using Python 3.x
    python3 setup.py
elif command -v python &> /dev/null; then
    python -m pip install inquirer # using Python 2.x
    python setup.py
else
    echo "Python is not installed. Please install Python."
fi

# Deactivate the virtual environment created by python
deactivate