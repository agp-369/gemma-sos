from kaggle.api.kaggle_api_extended import KaggleApi
import json

api = KaggleApi()
api.authenticate()

# Fetch kernel info
status = api.kernels_status('abhishekguptaagp/gemma4-sos-finetuning')
print("Status:", status)

try:
    # Try to get the output directly
    api.kernels_output('abhishekguptaagp/gemma4-sos-finetuning', 'notebooks/logs')
except Exception as e:
    print("Error fetching output:", e)
