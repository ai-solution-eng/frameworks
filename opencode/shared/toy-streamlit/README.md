```bash
# First time: create venv and install dependencies
python3 -m venv /workspace/shared/.venv-preview
/workspace/shared/.venv-preview/bin/pip install -r /workspace/shared/requirements.txt

# Run the app
/workspace/shared/.venv-preview/bin/streamlit run /workspace/shared/toy-streamlit/app.py --server.port 8511 --server.address 0.0.0.0 --server.enableCORS false --server.enableXsrfProtection false
```
