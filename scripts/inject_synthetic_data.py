import json
import os

notebook_path = "notebooks/finetune_unsloth_gemma4_sos.ipynb"

# Simulated synthetic data generation output
new_examples = [
    {"instruction": "Extract parameters from: Male, 30s, screaming in pain from crushed leg. Breathing very fast, counted 32 breaths per min. Pulse is present. Cannot walk.",
     "response": "{\"is_walking\": false, \"is_breathing\": true, \"respiratory_rate\": 32, \"has_radial_pulse\": true, \"capillary_refill_seconds\": 2, \"responds_to_voice\": true, \"responds_to_pain\": true, \"visible_injuries\": \"crushed leg\"}"},
    {"instruction": "Extract parameters from: Female victim found in rubble. Totally unresponsive to shouting or sternal rub. Chest is not rising at all. No pulse.",
     "response": "{\"is_walking\": false, \"is_breathing\": false, \"respiratory_rate\": 0, \"has_radial_pulse\": false, \"capillary_refill_seconds\": 5, \"responds_to_voice\": false, \"responds_to_pain\": false, \"visible_injuries\": \"unknown\"}"},
    {"instruction": "Extract parameters from: Found a teenager wandering around looking dazed. Scrape on forehead. Can answer questions, breathing normally.",
     "response": "{\"is_walking\": true, \"is_breathing\": true, \"respiratory_rate\": 16, \"has_radial_pulse\": true, \"capillary_refill_seconds\": 1, \"responds_to_voice\": true, \"responds_to_pain\": true, \"visible_injuries\": \"scrape on forehead\"}"},
    {"instruction": "Extract parameters from: Child sitting on ground. Breathing 24 times a minute. Good pulse. Can talk to me but leg is obviously broken so can't walk.",
     "response": "{\"is_walking\": false, \"is_breathing\": true, \"respiratory_rate\": 24, \"has_radial_pulse\": true, \"capillary_refill_seconds\": 1, \"responds_to_voice\": true, \"responds_to_pain\": true, \"visible_injuries\": \"broken leg\"}"},
    {"instruction": "Extract parameters from: Adult male, laying flat. Not breathing. Tilted head back and opened airway, still not breathing.",
     "response": "{\"is_walking\": false, \"is_breathing\": false, \"respiratory_rate\": 0, \"has_radial_pulse\": false, \"capillary_refill_seconds\": 5, \"responds_to_voice\": false, \"responds_to_pain\": false, \"visible_injuries\": \"none visible\"}"}
]

with open(notebook_path, 'r', encoding='utf-8') as f:
    notebook = json.load(f)

# Find the cell containing the disaster_qa definition
for cell in notebook['cells']:
    if cell['cell_type'] == 'code':
        source = "".join(cell['source'])
        if "disaster_qa = [" in source:
            # We will insert our new examples right after the array definition
            lines = cell['source']
            for i, line in enumerate(lines):
                if "disaster_qa = [" in line:
                    # Insert the new examples as a string block
                    insert_idx = i + 1
                    for ex in reversed(new_examples):
                        # Construct a clean string representation for the notebook
                        instr_escaped = ex['instruction'].replace('"', '\\"')
                        resp_escaped = ex['response'].replace('\\"', '\\\\"').replace('"', '\\"')
                        new_line = f"    {{\"instruction\": \"{instr_escaped}\",\n     \"response\": \"{resp_escaped}\"}},\n"
                        lines.insert(insert_idx, new_line)
                    break
            cell['source'] = lines
            break

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1)

print("Successfully injected synthetic Agentic Extraction examples into the notebook.")
