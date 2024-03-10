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
    python3 -m pip3 install pipenv # using Python 3.x
    pipenv --python $(which python3)
elif command -v python &> /dev/null; then
    python -m pip install pipenv # using Python 2.x
    pipenv --python $(which python)
else
    echo "Python is not installed. Please install Python."
fi

pipenv install

if command -v python3 &> /dev/null; then
    pipenv run python3 setup.py
elif command -v python &> /dev/null; then
    pipenv run python setup.py
else
    echo "Python is not installed. Please install Python."
fi

# Deactivate the virtual environment created by python
deactivate