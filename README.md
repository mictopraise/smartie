# Smartie

Smartie is a sharply scoped, fully offline AI assistant for African micro and small businesses. It converts rough business facts into customer replies, marketing copy, payment follow-ups, and short operating plans on an ordinary CPU laptop.

The competition artifact is the model repository itself. Smartie conforms to the official ADTC 2026 template: GGUF weights, `llama.cpp`, exactly two Corporate / Enterprise prompts, an idempotent public download script, and no network dependency during inference.

**Gate 1 status:** Submitted on Devpost. The repository is now preserved as the Gate 1 submission snapshot.

## Project links

- [Devpost submission](https://devpost.com/software/smartie)
- [Video demo](https://www.youtube.com/watch?v=t-9x1-0f17Y)
- [Technical report](REPORT.md)
- [Official profiler output](submission.json)

## Model choice

The baseline is **Qwen2.5-1.5B-Instruct Q4_K_M** (Apache-2.0). Its approximately 1.12 GB weight file leaves substantial headroom below the 7 GB measured memory budget while retaining much stronger instruction following than ultra-small demonstration models. Q4_K_M is the initial quality/throughput compromise; it is a baseline to measure, not an invented performance claim.

## Quick start (Ubuntu 22.04 / WSL)

Requirements: Python 3.11+, `curl`, and `llama-cli` from llama.cpp on `PATH`.

```bash
bash download_model.sh
python3 validate_submission.py
python3 smartie.py payment "A customer owes NGN 32,500, due yesterday. Write a warm WhatsApp reminder under 55 words."
```

If `llama-cli` is elsewhere:

```bash
LLAMA_CLI=/path/to/llama-cli python3 smartie.py plan "I run a small bakery..."
```

Smartie performs no network calls. Only `download_model.sh` uses the network, before inference.

## Tasks

- `reply`: concise service and customer-care messages
- `market`: channel-specific, low-cost marketing copy
- `plan`: short operational plans grounded in supplied facts
- `payment`: relationship-preserving payment follow-ups

Use `python3 smartie.py --help` for runtime options. Defaults deliberately cap context at 2,048 tokens, generation at 220 tokens, CPU threads at four, temperature at 0.2, and GPU layers at zero.

## Official profiling

Install the organizer's profiler and make sure `llama-bench` is on `PATH`:

```bash
python3 -m pip install "git+https://github.com/Africa-Deep-Tech-Foundation/adtc-profiler.git"
bash run_profiler.sh --skip-accuracy   # smoke test while iterating
bash run_profiler.sh                   # final participant run
```

The retained full participant run is recorded in `submission.json`. It measured **17.98 generation tokens/s**, **1,704.34 MB peak RSS**, and **0.74 ARC-Easy acc_norm** on 50 samples. The corresponding self-reported scores are **Sperf 100.00** and **Seff 76.22**. These are participant-laptop measurements, not predictions for the organizer's audit machine.

## Gate 1 archive

The submitted evidence is preserved in `metadata.json`, `submission.json`, and `REPORT.md`. Model weights remain excluded from Git and are reproducibly downloaded with `download_model.sh`.

Known limitation: the small local model is intended for constrained business writing and operating checklists. Numerical, legal, accounting, medical, and financial outputs require human verification.

Future work is intentionally separated from this snapshot: Android feasibility, a simpler interface, deterministic output validation, and an Ubuntu 22.04 / 8 GB hardware retest.

See `REPORT.md` for the technical narrative and `DEMO_PLAN.md` for the recording plan used for the submission.


