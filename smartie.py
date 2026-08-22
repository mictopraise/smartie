#!/usr/bin/env python3
"""Smartie: a zero-dependency offline business assistant over llama.cpp."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DEFAULT_MODEL = ROOT / "model" / "qwen2.5-1.5b-instruct-q4_k_m.gguf"

TASKS = {
    "reply": "Write a concise customer message. Preserve trust, include concrete facts, and end with one clear next step.",
    "market": "Create practical marketing copy for the stated channel and audience. Avoid unsupported claims and expensive tactics.",
    "plan": "Turn the facts into a short operating plan with priorities, owners if known, and measurable next actions.",
    "payment": "Draft a respectful payment follow-up. Preserve the relationship, state exact amounts and dates, and request a specific action.",
}

SYSTEM = """You are Smartie, an offline assistant for African micro and small businesses.
Use only facts supplied by the user. Never invent prices, laws, exchange rates, customer details, or market statistics.
When information is missing, state a brief assumption or ask for it. Keep currency exactly as supplied.
Prefer short, usable output in clear business English. Do arithmetic step by step and check it once.
Do not claim to be a lawyer, accountant, doctor, or financial adviser."""


def find_llama_cli(explicit: str | None) -> str:
    candidates = [explicit, os.environ.get("LLAMA_CLI"), "llama-cli", "llama.cpp-llama-cli"]
    for candidate in candidates:
        if not candidate:
            continue
        found = shutil.which(candidate)
        if found:
            return found
        if Path(candidate).is_file():
            return str(Path(candidate))
    raise SystemExit("llama-cli was not found. Install llama.cpp or set LLAMA_CLI to its path.")


def build_prompt(task: str, user_text: str) -> str:
    return (
        "<|im_start|>system\n" + SYSTEM + "<|im_end|>\n"
        "<|im_start|>user\nTask: " + TASKS[task] + "\n\n" + user_text.strip() +
        "<|im_end|>\n<|im_start|>assistant\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Smartie fully offline with a local GGUF model.")
    parser.add_argument("task", choices=TASKS)
    parser.add_argument("text", nargs="?", help="Business request; omit to read from standard input")
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--llama-cli", help="Path to llama-cli")
    parser.add_argument("--threads", type=int, default=min(4, os.cpu_count() or 1))
    parser.add_argument("--max-tokens", type=int, default=220)
    args = parser.parse_args()

    text = args.text if args.text is not None else sys.stdin.read()
    if not text.strip():
        parser.error("provide request text as an argument or through standard input")
    if not args.model.is_file():
        raise SystemExit(f"Model not found: {args.model}\nRun: bash download_model.sh")

    command = [
        find_llama_cli(args.llama_cli), "-m", str(args.model),
        "-p", build_prompt(args.task, text), "-n", str(args.max_tokens),
        "-c", "2048", "-t", str(args.threads), "-ngl", "0",
        "--temp", "0.2", "--top-p", "0.9", "--seed", "42",
        "--no-display-prompt", "--no-conversation",
    ]
    completed = subprocess.run(command, check=False)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())


