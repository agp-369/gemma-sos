# Gemma-SOS: Ollama Deployment

**Special Technology Track**: Ollama ($10k)

This directory contains the Ollama deployment configuration for Gemma-SOS, enabling completely offline, privacy-preserving disaster response AI on any device that can run Ollama.

## Quick Start

```bash
# Install Ollama (if not already installed)
# curl -fsSL https://ollama.com/install.sh | sh

# Pull the base Gemma 4 E2B model
ollama pull gemma-4-e2b-it

# Build the Gemma-SOS model
ollama create gemma-sos -f Modelfile

# Run it
ollama run gemma-sos
```

## API Usage

```python
import requests

response = requests.post("http://localhost:11434/api/generate", json={
    "model": "gemma-sos",
    "prompt": "Patient has capillary refill of 4 seconds. What triage category?",
    "stream": False,
})
print(response.json()["response"])
# Output: RED / Immediate. Perfusion deficit detected.
```

## Performance

| Device | Tokens/sec | Memory |
|--------|-----------|--------|
| MacBook M1 (16GB) | ~45 tok/s | ~4 GB |
| MacBook M4 (16GB) | ~60 tok/s | ~4 GB |
| RTX 4090 | ~140 tok/s | ~3 GB |
| T4 (Kaggle) | ~35 tok/s | ~3 GB |

## Combined with LiteRT

For maximum reach, use Ollama on laptops/desktops and LiteRT on mobile devices:

```
┌─────────────────────────────────────────────┐
│              Gemma-SOS Ecosystem             │
├─────────────────┬───────────────────────────┤
│  Mobile (LiteRT) │  Desktop (Ollama)         │
│  Gemma 4 E2B     │  Gemma 4 E2B/E4B         │
│  Android/iOS     │  Linux/macOS/Windows      │
│  ~22 tok/s       │  ~45-140 tok/s            │
│  2.58 GB model   │  2.58 GB model            │
└─────────────────┴───────────────────────────┘
```

## Fine-tuned Version

After running `notebooks/finetune_unsloth_gemma4_sos.ipynb`:

```bash
# Export Unsloth LoRA → GGUF
python scripts/export_gguf.py

# Create Ollama model from fine-tuned weights
ollama create gemma-sos-ft -f Modelfile-ft
```
