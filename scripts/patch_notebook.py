import json

notebook_path = "notebooks/finetune_unsloth_gemma4_sos.ipynb"

generation_code = """import random
import json

disaster_qa = []

# --- 1. GENERATE 500 START TRIAGE SCENARIOS ---
demographics = ['Adult male', 'Elderly female', 'Teenage boy', 'Child', '30yo woman', 'Middle-aged man', 'Senior citizen', 'Young girl', '25yo male']
mechanisms = ['crushed under rubble', 'hit by debris', 'with a severe head wound', 'coughing from smoke inhalation', 'with a severely bleeding leg', 'with a broken arm', 'unconscious on the ground', 'pinned under a beam', 'with severe burns']

# Triage logic generator
for i in range(500):
    demo = random.choice(demographics)
    mech = random.choice(mechanisms)
    
    is_walking = random.random() < 0.2
    is_breathing = random.random() < 0.9 if not is_walking else True
    
    if is_walking:
        resp_rate = random.randint(12, 24)
        has_radial_pulse = True
        cap_refill = random.randint(1, 2)
        resp_voice = True
        resp_pain = True
        desc = f"Patient is walking around. {demo} {mech}."
    elif not is_breathing:
        resp_rate = 0
        has_radial_pulse = False
        cap_refill = 5
        resp_voice = False
        resp_pain = False
        desc = f"Patient is not breathing. {demo} {mech}. Opened airway, still no breathing."
    else:
        # RED or YELLOW
        is_red = random.random() < 0.5
        if is_red:
            reason = random.choice(['resp', 'pulse', 'mental'])
            if reason == 'resp':
                resp_rate = random.choice([random.randint(4, 9), random.randint(31, 45)])
                has_radial_pulse = True
                cap_refill = 2
                resp_voice = True
                resp_pain = True
            elif reason == 'pulse':
                resp_rate = random.randint(12, 28)
                has_radial_pulse = False
                cap_refill = random.randint(3, 5)
                resp_voice = True
                resp_pain = True
            else:
                resp_rate = random.randint(12, 28)
                has_radial_pulse = True
                cap_refill = 2
                resp_voice = False
                resp_pain = False
        else: # YELLOW
            resp_rate = random.randint(10, 30)
            has_radial_pulse = True
            cap_refill = random.randint(1, 2)
            resp_voice = True
            resp_pain = True
            
        pulse_str = "Strong pulse" if has_radial_pulse else "No radial pulse"
        mental_str = "follows commands" if resp_voice else "unresponsive to voice and pain"
        desc = f"{demo} {mech}. Cannot walk. Breathing at {resp_rate} breaths/min. {pulse_str}. Patient {mental_str}."
        
    ans_json = {
        "is_walking": is_walking,
        "is_breathing": is_breathing,
        "respiratory_rate": resp_rate,
        "has_radial_pulse": has_radial_pulse,
        "capillary_refill_seconds": cap_refill,
        "responds_to_voice": resp_voice,
        "responds_to_pain": resp_pain,
        "visible_injuries": "unknown"
    }
    
    disaster_qa.append({
        "instruction": f"Extract triage parameters from: {desc}",
        "response": json.dumps(ans_json)
    })

# --- 2. GENERATE 200 FEMA Q&A PAIRS ---
fema_templates = [
    ("What do I do during an earthquake?", "DROP, COVER, and HOLD ON. Drop to hands and knees. Cover head and neck under sturdy table. Hold on until shaking stops."),
    ("I smell gas after the earthquake, what should I do?", "Evacuate immediately. Do NOT use matches, lighters, or light switches. Call 911 once outside."),
    ("Can I drive through flooded water?", "NO. Turn around, don't drown. Just 12 inches of flowing water can carry away most vehicles."),
    ("How do I escape a fire?", "Stay low, crawl under the smoke. Check doors with the back of your hand before opening. Use stairs, never elevators."),
    ("How long do earthquake aftershocks last?", "Aftershocks can continue for days to weeks. Drop, Cover, and Hold On during each one."),
    ("How do I purify water?", "Boil for 1 minute, or use 8 drops of unscented household bleach per gallon and wait 30 minutes."),
    ("I am trapped under rubble, how do I signal?", "Tap on a pipe or wall 3 times. Do not light a match. Shout only as a last resort so you don't inhale dust.")
]

for i in range(200):
    q, a = random.choice(fema_templates)
    # Add slight variation to instruction to simulate real user inputs
    prefix = random.choice(['Help! ', 'Quick question: ', '', 'Urgent: ', 'FEMA protocol for: '])
    disaster_qa.append({
        "instruction": prefix + q,
        "response": a
    })

print(f"[+] Procedurally generated {len(disaster_qa)} massive synthetic training examples.")
"""

with open(notebook_path, 'r', encoding='utf-8') as f:
    notebook = json.load(f)

for cell in notebook['cells']:
    if cell['cell_type'] == 'code':
        source = "".join(cell['source'])
        if "disaster_qa = [" in source:
            # Replace the entire cell source with our procedural generator
            # Split lines and append newlines so Jupyter renders it correctly
            cell['source'] = [line + '\\n' for line in generation_code.split('\\n')]
            # Fix the last line newline issue
            if cell['source']:
                cell['source'][-1] = cell['source'][-1].rstrip('\\n')
            break

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1)

print("Notebook updated with massive synthetic generation script.")
