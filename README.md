# Gemma-SOS

**Offline disaster response assistant powered by Gemma 4 E2B.**  
Runs entirely on-device. No internet. No cloud. Just a phone.

## What this is

A Flutter Android app that loads a fine-tuned Gemma 4 E2B model locally and uses it for medical triage, SOS broadcasts, and peer-to-peer data sharing in disaster scenarios where networks are down.

The model was fine-tuned on 2000 synthetic triage cases using Unsloth + LoRA on a Kaggle T4 GPU. The final loss was 0.1424. The LoRA adapter (124 MB) is the only thing separating a general Gemma 4 from a disaster response specialist.

## Features

- **START Protocol Triage** — Natural language or toggle-based patient assessment. Categorizes as Immediate/Delayed/Minimal/Deceased.
- **SOS Beacon** — One-tap emergency broadcast with GPS coordinates.
- **Mesh Sync** — QR-based patient data transfer between phones. No network needed.
- **Wreckage Analyzer** — Structural hazard assessment via camera (requires GPU).
- **Offline Maps** — GPS location with resource finder (shelter, hospital, water).

## Architecture

```
Training (Kaggle T4):
  Gemma 4 E2B 4-bit → Unsloth LoRA rank 16 → 0.14 loss

Deployment (Infinix Smart 7 / Helio G37):
  .litertlm model file (2.59 GB) → flutter_gemma → LiteRT-LM CPU backend
  LoRA adapter → applied at model load
```

The model runs via LiteRT-LM's FFI path using XNNPack-optimized CPU inference. First load builds a weight cache (~4 min). Subsequent inference takes 10-15 seconds per response on this hardware.

## Project Structure

```
lib/
  main.dart                    — App entry + splash screen
  services/
    gemma_service.dart         — Model loading, text inference
    gemma_triage_service.dart  — LLM-based triage parsing
    triage_engine.dart         — Local START protocol engine
    patient_repository.dart    — SQLite patient storage
    mesh_service.dart          — QR sync encoding/decoding
    gps_service.dart           — Location service
  ui/
    triage_dashboard.dart      — Main dashboard
    medical_triage_screen.dart — Triage form + patient list
    sos_screen.dart            — SOS beacon
    offline_maps_screen.dart   — GPS + resource finder
    widgets/
      wreckage_analyzer.dart   — Camera-based structural analysis
android/                       — Android config, permissions, R8 rules
assets/models/                 — Model file location (add your own .litertlm)
notebooks/                     — Unsloth fine-tuning notebook
```

## Running It Yourself

### On Your Phone

1. Get the base Gemma 4 E2B model in `.litertlm` format (2.59 GB)
2. Push it to your phone:  
   `adb push gemma-4-E2B-it.litertlm /storage/emulated/0/Android/data/com.example.gemma_sos/files/`
3. Build and install:  
   `flutter build apk --release && adb install build/app/outputs/flutter-apk/app-release.apk`
4. Launch the app. First load copies the model to private storage and builds XNNPack cache (~4 min).

### Fine-tuning Your Own

The notebook at `notebooks/finetune_unsloth_gemma4_sos.ipynb` contains the full pipeline. It runs on a Kaggle T4 GPU with Unsloth. Expected training time: ~70 minutes.

## Known Limitations

- **Vision doesn't work on CPU-only devices.** Gemma 4's multimodal features need GPU acceleration. Text features work fine.
- **LoRA loading on .litertlm is unsupported** in flutter_gemma 0.15.1's FFI path. The base model runs; the fine-tuned adapter loads in the training environment.
- **XNNPack can be unstable** on certain ARM CPUs. Tensor shape mismatches can crash inference on some hardware.

## Links

- [Kaggle Notebook](https://www.kaggle.com/code/abhishekguptaagp/gemma4-sos-finetuning)
- [Fine-tuned LoRA Weights](https://huggingface.co/agp-369/gemma-4-e2b-sos-lora)
- [Competition Writeup](https://www.kaggle.com/competitions/gemma-4-good-hackathon/writeups/...)
- [Unsloth Track Details](https://unsloth.ai/docs/models/gemma-4/train.md)
