```bash
# First time: create venv and install dependencies
python3 -m venv /workspace/shared/.venv-preview
/workspace/shared/.venv-preview/bin/pip install -r /workspace/shared/requirements.txt

# Run the app
/workspace/shared/.venv-preview/bin/uvicorn main:app --app-dir /workspace/shared/toy-uvicorn --host 0.0.0.0 --port 8011
```
