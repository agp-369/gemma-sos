import json
import os

notebook_path = "notebooks/finetune_unsloth_gemma4_sos.ipynb"

with open(notebook_path, 'r', encoding='utf-8') as f:
    notebook = json.load(f)

# 1. Fix Markdown Cell
markdown_source = [
    "# Gemma-SOS: Fine-Tuning for Disaster Response\n",
    "\n",
    "This notebook trains Gemma 4 for offline disaster response and medical triage.\n",
    "\n",
    "## Overview\n",
    "- **Model**: `google/gemma-4-E2B-it`\n",
    "- **Library**: Unsloth\n",
    "- **Data**: Synthetic START Triage & FEMA scenarios\n",
    "- **Output**: `.litertlm` for mobile inference\n"
]

# 2. Fix Gated Model Auth Issue (Add Kaggle Secrets)
auth_code = [
    "# Setup Hugging Face Token for Gated Models\n",
    "import os\n",
    "try:\n",
    "    from kaggle_secrets import UserSecretsClient\n",
    "    user_secrets = UserSecretsClient()\n",
    "    os.environ['HF_TOKEN'] = user_secrets.get_secret('HF_TOKEN')\n",
    "    print('HF Token loaded from Kaggle Secrets.')\n",
    "except Exception as e:\n",
    "    print('Not running on Kaggle or HF_TOKEN secret not found.')\n"
]

# Locate markdown cell and replace it
for cell in notebook['cells']:
    if cell['cell_type'] == 'markdown' and 'Gemma-SOS: Fine-Tune' in "".join(cell.get('source', [])):
        cell['source'] = markdown_source
        break

# Inject auth cell before the Unsloth import cell
auth_cell_injected = False
new_cells = []
for cell in notebook['cells']:
    if cell['cell_type'] == 'code' and 'import torch' in "".join(cell.get('source', [])) and not auth_cell_injected:
        new_cells.append({
            "cell_type": "code",
            "execution_count": None,
            "metadata": {},
            "outputs": [],
            "source": auth_code
        })
        auth_cell_injected = True
    
    # Format the large single-string code cell back to standard jupyter format
    if cell['cell_type'] == 'code':
        src = "".join(cell.get('source', []))
        if "disaster_qa = []" in src and "import random" in src:
            # Re-split properly
            lines = src.split('\n')
            cell['source'] = [line + '\n' for line in lines[:-1]] + ([lines[-1]] if lines[-1] else [])
            
    new_cells.append(cell)

notebook['cells'] = new_cells

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1)

print("Notebook fixed: Markdown simplified, Auth added, Code formatting normalized.")
