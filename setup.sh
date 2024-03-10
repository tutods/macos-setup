if command -v python3 &> /dev/null; then
    python3 -m pip install --user pipenv
    pipenv --python $(which python3)
    pipenv install
    pipenv run python3 setup.py
elif command -v python &> /dev/null; then
    python -m pip install --user pipenv
    pipenv --python $(which python)
    pipenv install
    pipenv run python setup.py
else
    echo "Python is not installed. Please install Python."
fi