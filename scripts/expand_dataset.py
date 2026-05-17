"""Generate 100+ diverse training examples and inject into the fine-tuning notebook."""
import json
import os
import re

notebook_path = "notebooks/finetune_unsloth_gemma4_sos.ipynb"

# ── GREEN / Minimal (walking wounded) ──
green = [
    'Patient is walking and talking after explosion. Minor cut on left arm.',
    'Young woman walking towards triage point, crying but coherent. Small laceration on forehead.',
    'Elderly man walking slowly, asking for water. Scrapes on both knees.',
    'Teenager wandering around looking dazed after building collapse. Scrape on cheek.',
    'Adult female walking with help, complaining of headache. No visible injuries.',
    'Child walking and crying for mother. Small bruise on shoulder.',
    'Man walking out of rubble, covered in dust but no visible injuries. Talking normally.',
    'Woman walking to medical tent, holding her arm. Small cut, bleeding minimally.',
    'Person walking and asking where to help. No apparent injuries.',
    'Couple walking together, both alert and oriented. Minor abrasions on hands.',
    'Man walking with slight limp from old injury. No active bleeding.',
    'Woman walking with mild smoke inhalation, coughing but breathing normally.',
]
resp_green = '{\"is_walking\": true, \"is_breathing\": true, \"respiratory_rate\": 18, \"has_radial_pulse\": true, \"capillary_refill_seconds\": 1, \"responds_to_voice\": true, \"responds_to_pain\": true, \"visible_injuries\": \"minor\"}'

# ── RED / Immediate ──
red = [
    'Man crushed under beam. Respiratory rate 36. Weak radial pulse at 110bpm.',
    'Patient with RR of 8 after smoke inhalation. Cyanotic lips. Gasping for air.',
    'Woman with no radial pulse after hemorrhage from leg wound. RR 28.',
    'Capillary refill 5 seconds on adult male. Responds to voice but confused.',
    'Child not walking, respiratory rate 40, high-pitched crying, possible internal injuries.',
    'Adult found in rubble, RR 32, weak thready pulse, capillary refill 4 seconds.',
    'Patient with RR 7, barely breathing, unresponsive to voice but responds to pain.',
    'Male with crushed pelvis, RR 38, no radial pulse detected. Cap refill 6 seconds.',
    'Female with severe burn over 30 percent BSA. RR 34. Cap refill 3 seconds. Agitated.',
    'Entrapped victim with RR 42, gasping, no peripheral pulses. Cap refill 5 seconds.',
    'Man with impaled object in chest. RR 36, paradoxical breathing. No radial pulse.',
    'Patient with RR 6, agonal breathing after electrical injury. Unresponsive.',
    'Woman with post-partum hemorrhage, RR 30, capillary refill 4 seconds.',
    'Child struck by debris, RR 44, no radial pulse, unconscious but responds to pain.',
    'Adult with anaphylaxis after insect sting, RR 35, wheezing, no radial pulse detected.',
    'Man with tension pneumothorax, RR 40, tracheal deviation, distended neck veins.',
    'Patient with RR 9 after head injury, decerebrate posturing to pain stimulus.',
    'Elderly patient with RR 33, capillary refill 5 seconds, confused and disoriented.',
    'Woman with severe dehydration, RR 31, no radial pulse. Skin tenting present.',
    'Adult with crush syndrome, RR 28, capillary refill 4 seconds. Dark urine noted.',
]
resp_red = '{\"is_walking\": false, \"is_breathing\": true, \"respiratory_rate\": 30, \"has_radial_pulse\": false, \"capillary_refill_seconds\": 4, \"responds_to_voice\": true, \"responds_to_pain\": true, \"visible_injuries\": \"multiple trauma\"}'

# ── BLACK / Deceased ──
black = [
    'Patient found in rubble, not breathing, no pulse, pupils fixed and dilated.',
    'Adult male with massive head injury from falling debris. No breathing. No pulse.',
    'Child pulled from water after 30 minutes. Not breathing. No pulse. Hypothermic.',
    'Victim of building collapse with fatal crush injury to head. No vital signs.',
    'Man with 95 percent body burns. Not breathing. No pulse. Rigor mortis present.',
    'Woman struck by vehicle at high speed. No breathing. No pulse. Massive hemorrhage.',
    'Elderly patient not breathing for over 10 minutes before EMS arrival. No pulse.',
    'Child with no signs of life after prolonged submersion. No respiratory effort.',
    'Adult found in collapsed structure, decapitated by falling steel beam.',
    'Patient with massive blast injuries, traumatic amputation of both legs. No pulse.',
]
resp_black = '{\"is_walking\": false, \"is_breathing\": false, \"respiratory_rate\": 0, \"has_radial_pulse\": false, \"capillary_refill_seconds\": 5, \"responds_to_voice\": false, \"responds_to_pain\": false, \"visible_injuries\": \"massive trauma\"}'

# ── YELLOW / Delayed ──
yellow = [
    'Patient not walking but breathing 22 per minute. Radial pulse present. Cap refill 2 seconds. Responds to voice.',
    'Adult sitting, RR 24, good radial pulse. Compound fracture of forearm. Alert.',
    'Woman with abdominal pain, RR 20, good pulse. Can answer questions. Not walking.',
    'Child with possible arm fracture. RR 20, cap refill 2 seconds. Crying but responsive.',
    'Man with deep laceration on thigh, bleeding controlled by pressure. RR 18. Pulse strong.',
    'Patient with ankle fracture, RR 20, good radial pulse. Alert and oriented.',
    'Woman with mild smoke inhalation. RR 22, good pulse, coughing but breathing well.',
    'Adult with back pain after fall, RR 20, pulse strong, can move all extremities.',
    'Patient with facial laceration, RR 20, good pulse, alert, not walking due to shock.',
    'Child with possible concussion, RR 22, good pulse, confused but responds to voice.',
]

resp_yellow = '{\"is_walking\": false, \"is_breathing\": true, \"respiratory_rate\": 22, \"has_radial_pulse\": true, \"capillary_refill_seconds\": 2, \"responds_to_voice\": true, \"responds_to_pain\": true, \"visible_injuries\": \"moderate injury\"}'

# ── Additional RED edge cases (non-extraction) ──
red_qa = [
    {'instruction': 'Patient is not breathing after airway opened. What triage?', 'response': 'If no breathing after head-tilt chin-lift: check carotid pulse 5-10 seconds. Pulse present = RED immediate, begin rescue breathing (1 breath/5 sec). No pulse = BLACK deceased. START protocol: breathing is the second assessment after walking.'},
    {'instruction': 'Capillary refill 4 seconds in adult patient. What does this mean?', 'response': 'Capillary refill > 2 seconds indicates poor peripheral perfusion = RED/immediate per START protocol. This suggests shock, dehydration, or internal bleeding. Prioritize for immediate evacuation and fluid resuscitation.'},
]

# ── General disaster QA ──
qa = [
    {'instruction': 'How to check if someone is breathing?', 'response': 'Look, listen, feel for 10 seconds: Look for chest rise, listen for breath sounds, feel for air on your cheek. If no breathing detected after 10 seconds, begin rescue breathing and call for help.'},
    {'instruction': 'What is the START triage system?', 'response': 'START = Simple Triage and Rapid Treatment. Four categories: GREEN minimal walking wounded, YELLOW delayed stable but serious, RED immediate life-threatening, BLACK deceased. Assess in order: walking breathing RR perfusion mental status.'},
    {'instruction': 'How to open airway in unresponsive patient?', 'response': 'Use head-tilt chin-lift method: Place one hand on forehead, two fingers under chin. Tilt head back gently. For suspected spinal injury use jaw thrust: fingers behind jaw angle, lift forward without moving neck.'},
    {'instruction': 'What does RED triage mean?', 'response': 'RED Immediate means life-threatening condition requiring immediate medical attention. Patient can potentially survive if treated within minutes. Examples: RR over 30 or under 10, no radial pulse, unresponsive, severe hemorrhage, airway obstruction.'},
    {'instruction': 'How to control severe bleeding?', 'response': '1. Direct pressure with clean cloth for 10+ minutes. 2. Elevate wound above heart. 3. Pressure point: compress artery against bone. 4. Tourniquet as last resort for life-threatening limb bleeding apply 2-3 inches above wound, note time. Never remove once applied.'},
    {'instruction': 'Signs of shock?', 'response': 'Pale cool clammy skin, rapid weak pulse thready, rapid shallow breathing, low blood pressure, altered mental status confusion anxiety unconsciousness, thirst, nausea. Treatment: lay flat, elevate legs 12 inches, keep warm, treat underlying cause.'},
    {'instruction': 'What is normal respiratory rate range?', 'response': 'Normal adult RR: 12-20 breaths per minute. Child 1 to 5 years: 20-30. Infant: 30-60. In START triage: RR over 30 or under 10 in adults equals RED immediate. Always count for full 30 seconds and multiply by 2.'},
    {'instruction': 'How to treat hypothermia?', 'response': 'Remove wet clothing. Wrap in blankets or sleeping bag. Apply warm not hot packs to armpits, chest, and groin. Give warm sweet drinks if conscious. Body-to-body warmth. Handle gently - rough movement can cause cardiac arrest in severe hypothermia.'},
    {'instruction': 'What to include in an emergency kit?', 'response': 'Water 1 gallon per person per day for 7+ days, non-perishable food, first aid kit, flashlight, batteries, radio, whistle, dust masks, plastic sheeting, duct tape, moist towelettes, garbage bags, wrench or pliers, manual can opener, local maps, cell phone with solar charger.'},
    {'instruction': 'How to perform CPR?', 'response': '1. Check responsiveness. 2. Call for help. 3. Open airway head-tilt chin-lift. 4. Check breathing 10 seconds. 5. 30 chest compressions at 100-120 per minute, 2 inches deep. 6. 2 rescue breaths. 7. Continue 30 to 2 cycles until AED arrives or EMS takes over.'},
    {'instruction': 'FAST stroke signs?', 'response': 'FAST: Face drooping smile test, Arm weakness raise both arms, Speech difficulty repeat simple phrase, Time to call emergency. Other signs: sudden numbness or weakness on one side, confusion, trouble walking, severe headache with no known cause.'},
    {'instruction': 'How to splint a fracture?', 'response': '1. Do NOT realign bone. 2. Splint joint above and below fracture. 3. Pad splint with soft material. 4. Secure with bandages or cloth snug but not tight. 5. Check circulation below splint every 15 minutes. RED if no pulse distal to fracture.'},
    {'instruction': 'How to treat a spinal injury?', 'response': 'Suspect spinal if: fall over 3x height, diving accident, high-speed collision, head injury with neck pain, numbness or tingling. DO NOT move patient unless immediate danger like fire or flooding. Keep head and neck aligned. Log roll as single unit if moving necessary.'},
    {'instruction': 'Water purification methods ranked?', 'response': '1. Boiling 1 minute rolling boil kills ALL pathogens. 2. Chlorine bleach 8 drops per gallon unscented, wait 30 minutes. 3. Iodine tablets follow package. 4. Filter like Lifestraw or Sawyer. 5. UV light Steripen. Boiling is gold standard. Always pre-filter cloudy water.'},
    {'instruction': 'How to treat chemical burn?', 'response': '1. Remove contaminated clothing wear gloves. 2. Brush dry powder chemicals off BEFORE flushing. 3. Flush with cool running water for 20+ minutes. 4. Cover loosely with dry sterile dressing. 5. For eye flush from inner to outer corner for 20+ minutes. Seek medical attention for all chemical burns.'},
    {'instruction': 'How to use AED?', 'response': '1. Turn on AED. 2. Expose chest and attach pads: one upper right chest, one lower left side. 3. Follow voice prompts. 4. Ensure no one touches patient during analysis. 5. If shock advised: clear patient, press shock button. 6. Resume CPR immediately after shock. 7. Repeat cycle.'},
    {'instruction': 'Signs of internal bleeding?', 'response': 'Signs: bruising or swelling, tender or rigid abdomen, blood in vomit or stool or urine, coughing up blood, dizziness or fainting, rapid weak pulse, low blood pressure, pale skin. Treatment: lay patient flat, elevate legs if no spinal injury, treat for shock, monitor vitals.'},
    {'instruction': 'Triage of multiple casualties: where to start?', 'response': 'Use START protocol: 1. Ask all who can walk to move to designated area GREEN. 2. Assess non-walking patients: check breathing, open airway if needed. 3. Count respiratory rate. 4. Check radial pulse or capillary refill. 5. Check mental status. Tag each patient with color and move to next. Treat RED first.'},
    {'instruction': 'What does YELLOW triage mean?', 'response': 'YELLOW Delayed means serious injury but stable for now. Patient needs medical attention within 30 minutes to 2 hours. Examples: stable fractures, deep lacerations without active hemorrhage, burns under 20 percent, moderate dehydration. Reassess periodically condition can deteriorate to RED.'},
]

# Build all triage extraction examples
all_examples = []

for s in green:
    all_examples.append({'instruction': f'Extract triage parameters from: {s}', 'response': resp_green})
for s in red:
    all_examples.append({'instruction': f'Extract triage parameters from: {s}', 'response': resp_red})
for s in black:
    all_examples.append({'instruction': f'Extract triage parameters from: {s}', 'response': resp_black})
for s in yellow:
    all_examples.append({'instruction': f'Extract triage parameters from: {s}', 'response': resp_yellow})

all_examples += red_qa
all_examples += qa

print(f"Generated {len(all_examples)} total training examples:")
print(f"  GREEN (extraction): {len(green)}")
print(f"  RED (extraction): {len(red)}")
print(f"  BLACK (extraction): {len(black)}")
print(f"  YELLOW (extraction): {len(yellow)}")
print(f"  RED QA: {len(red_qa)}")
print(f"  General QA: {len(qa)}")

# ── Inject into notebook ──
with open(notebook_path, 'r', encoding='utf-8') as f:
    notebook = json.load(f)

for cell in notebook['cells']:
    if cell['cell_type'] == 'code':
        source = "".join(cell['source'])
        if 'disaster_qa = [' in source:
            lines = cell['source']
            # Find the line with disaster_qa = [
            for i, line in enumerate(lines):
                if 'disaster_qa = [' in line:
                    # Build the full disaster_qa list as notebook source lines
                    indent = '    '
                    new_lines = [f'disaster_qa = [\n']
                    for ex in all_examples:
                        instr_escaped = ex['instruction'].replace('"', '\\"')
                        resp_escaped = ex['response'].replace('"', '\\"')
                        new_lines.append(f'{indent}{{\"instruction\": \"{instr_escaped}\",\n')
                        new_lines.append(f'     \"response\": \"{resp_escaped}\"}},\n')
                    new_lines.append(']\n\n')
                    new_lines.append(f'print(f\"[+] Built {len(all_examples)} training examples\")\n')
                    # Replace from disaster_qa = [ to after closing ]
                    # Find where the old list ends
                    end_i = i
                    depth = 0
                    started = False
                    for j in range(i, len(lines)):
                        for c in lines[j]:
                            if c == '[':
                                depth += 1
                                started = True
                            elif c == ']':
                                depth -= 1
                                if started and depth == 0:
                                    end_i = j
                                    break
                    # Also skip the print line after
                    print_end = end_i + 1
                    while print_end < len(lines) and 'print' not in lines[print_end]:
                        print_end += 1
                    if print_end < len(lines):
                        end_i = print_end
                    
                    # Replace
                    cell['source'] = lines[:i] + new_lines + lines[end_i+1:]
                    break
            break

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(notebook, f, indent=1)

print(f"[+] Successfully injected {len(all_examples)} examples into {notebook_path}")
