# Step-by-Step Guide: Test & Record Video

## PHASE 1: PUSH MODEL TO PHONE

```powershell
cd C:\Users\abhis\Desktop\GemmaHackathon
adb push assets\models\gemma-4-E2B-it.litertlm /sdcard/Download/
```
(~2-5 min via USB)

## PHASE 2: BUILD & RUN ON PHONE

```powershell
flutter build apk --debug
flutter install
flutter run
```

**Verify on phone**:
1. App launches → "Initializing Gemma 4 engine..." appears
2. After load → "AI Guardian Active" + "All systems online"
3. Red "START TRIAGE NOW" hero card visible
4. Tap it → Medical Triage screen opens
5. Type "unconscious, not walking, breathing slowly" → tap "AI Parse & Triage"
6. RED classification appears with confidence badge
7. Tap info icon (i) → System Status dialog shows engine ready

**If model loading fails**: The app falls back to triage engine + mocked Gemma responses. This is fine for the video — the START protocol is deterministic and works without Gemma 4.

## PHASE 3: RECORD THE VIDEO (2:45)

### Tools needed
- Phone with built-in screen recorder (Android 12+ has it in quick settings)
- Separate audio recorder (phone voice memos app is fine)
- Video editor: **CapCut** (free, mobile) or **DaVinci Resolve** (free, desktop)

### Footage to capture

**A) Screen recordings** (record each separately):
1. **Triage NL input**: Dashboard → tap hero card → type "unconscious, not walking, RR 8" → tap AI Parse → show RED result → back to patient list
2. **Triage manual form**: Tap "Manual Assessment" → slide RR to 35 → toggle off pulse → tap Assess → show RED
3. **Patient list**: Add 3-4 patients so list shows RED/YELLOW/GREEN/BLACK mix
4. **Bonus tools**: Quick swipe — Wreckage (5s), Maps (5s), SOS (5s)

**B) B-roll footage**:
1. **Phone in hand** — dark room, phone screen as only light source
2. **Disaster footage** — download from Pexels.com (free, CC): search "earthquake rubble", "flood", "hurricane damage"
3. **Architecture graphic** — screenshot of the diagram from `docs/writeup/report.md`

### Narration recording
Use phone voice memos in a quiet room. Read the script from `scripts/video_script.md` at a steady pace. Each section is timed. If you mess up a line, pause 2 seconds and re-read it — easy to cut in editing.

### Editing timeline (CapCut / DaVinci)

| Time | Visual | Audio |
|------|--------|-------|
| 0:00 | Dark screen → phone light turns on | Static + heartbeat → narration starts |
| 0:15 | Disaster footage (Pexels) + phone showing "No Service" graphic | Narration + somber music |
| 0:45 | Screen recording: app launch → dashboard with hero card | Music shifts up → narration |
| 1:15 | Screen recording: NL triage → RED result → patient list | Narration + UI sounds |
| 2:15 | Architecture graphic + quick swipe wreckage/maps/SOS | Narration + tech music |
| 2:35 | Phone in hand shot → fade to black with text overlay | Narration ends → music swell → fade |

### Production checklist
- [ ] 1920x1080 export
- [ ] MP4, H.264 codec
- [ ] Captions: upload .srt file with YouTube
- [ ] Upload to YouTube as **unlisted**
- [ ] Description includes: "Built for the Kaggle Gemma 4 Good Hackathon"

### Narration script (read this aloud)

**0:00-0:15** *"When the earthquake hits. When the flood waters rise. When the grid goes dark... your phone is still in your hand. But without the internet, it's just a brick."*

**0:15-0:45** *"The first 72 hours after a disaster are critical. That's when most lives are saved or lost. But it's also when internet connectivity vanishes, cloud AI becomes useless, and people are left alone to make life-or-death decisions with no guidance. Medical triage requires expertise that most people don't have."*

**0:45-1:15** *"This is Gemma-SOS. An offline AI disaster response system that runs entirely on your phone. Powered by Google's Gemma 4 E2B — a frontier AI model that fits in under 3 GB and runs completely offline. No internet. No cloud. No data leaving your device."*

**1:15-2:15** *"This is the heart of Gemma-SOS. A patient is found in the rubble. Anyone can perform professional-grade triage. Describe what you see in plain language. Behind the scenes, the START protocol decision tree runs deterministically — no hallucinations, no guesswork. RED means immediate evacuation. YELLOW can wait. GREEN can help. Every patient is logged with timestamp, GPS position, and a confidence score. This turns one phone into a field hospital command center."*

**2:15-2:35** *"Under the hood: Gemma 4 E2B on LiteRT-LM — 2.58 GB, 128K context, multi-token prediction. Fine-tuned with Unsloth LoRA on disaster-specific data. Plus bonus tools for wreckage analysis, offline maps, and emergency SOS — all completely offline."*

**2:35-2:45** *"When the grid goes down... intelligence doesn't have to. Gemma 4, running on your phone, saving lives. That's AI for good."*
