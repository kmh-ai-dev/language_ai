#!/usr/bin/env python3
"""
translate.py

Command-line translator using Ollama + Qwen2.5 (default).

Features:
- Translate a single input file to a single output file.
- Translate all .txt files in a directory (batch mode).
- Specify model (default: `qwen2.5:7b`).
- Override the system prompt template.

Usage:
  # single file
  python3 translate.py input_kr.txt output_en.txt

  # specify model
  python3 translate.py input_kr.txt output_en.txt --model qwen2.5:14b

  # translate all .txt files in a directory (outputs with .en.txt suffix)
  python3 translate.py --dir ./in_dir --outdir ./out_dir

Requirements:
  pip install --user ollama

Notes:
  - This script uses the `ollama` Python package to call the local Ollama server.
  - The Ollama server must be running (e.g. `ollama serve &` or via brew services).
"""

from __future__ import annotations

import argparse
import os
import sys
from typing import Optional

try:
    import pyperclip
except ImportError:
    pyperclip = None


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def build_messages(text: str, system_prompt: Optional[str] = None) -> list:
    sys_prompt = (
        system_prompt
        if system_prompt
        else (
            "You are a professional translator. If the input text is primarily in Korean, translate it to English. "
            "If the input text is primarily in English, translate it to Korean. "
            "Translate accurately, preserving meaning, intent, technical terms, and code snippets. "
            "Crucially, you must ONLY output the translated text itself. Do NOT add any conversational text, explanations, or notes."
        )
    )
    return [
        {"role": "system", "content": sys_prompt},
        {"role": "user", "content": f"Please translate the following text:\n\n{text}"},
    ]


def translate_text_with_ollama(text: str, model: str, system_prompt: Optional[str] = None) -> str:
    try:
        import ollama
    except Exception as exc:  # ImportError or other
        eprint("Python package 'ollama' is required. Install with: python3 -m pip install --user ollama")
        raise

    messages = build_messages(text, system_prompt)
    # Use chat API
    resp = ollama.chat(model=model, messages=messages)
    # Extract content from response
    if hasattr(resp, 'message') and hasattr(resp.message, 'content'):
        english = resp.message.content
    else:
        # Fallback for dict response
        english = resp.get("message", {}).get("content") or resp.get("content") or str(resp)
    return english


def translate_text(text: str, model: str = "qwen2.5:7b", system_prompt: Optional[str] = None) -> str:
    """Translate text bidirectionally (Korean <-> English) using Ollama."""
    return translate_text_with_ollama(text, model, system_prompt)


def translate_file(input_path: str, output_path: str, model: str, system_prompt: Optional[str] = None):
    if not os.path.isfile(input_path):
        raise FileNotFoundError(input_path)
    with open(input_path, "r", encoding="utf-8") as f:
        text = f.read().strip()
    if not text:
        eprint(f"Warning: input file is empty: {input_path}")
        translated = ""
    else:
        translated = translate_text(text, model, system_prompt)
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(translated)
    print(f"Translated {input_path} -> {output_path} using model {model}")


def main(argv: Optional[list] = None):
    p = argparse.ArgumentParser(description="Translate text files bidirectionally (Korean <-> English) using Ollama.")
    p.add_argument("input", nargs="?", help="input file (or omit when using --dir or stdin)")
    p.add_argument("output", nargs="?", help="output file (or omit when using --dir or stdout)")
    p.add_argument("--model", default="qwen2.5:7b", help="model to use (default: qwen2.5:7b)")
    p.add_argument("--dir", help="translate all .txt files in this input directory (batch mode)")
    p.add_argument("--outdir", help="output directory for batch mode (default: input_dir/_en)")
    p.add_argument("--suffix", default=".en.txt", help="suffix for batch outputs (default: .en.txt)")
    p.add_argument("--system-prompt", help="override system prompt used for translation")
    p.add_argument("--clipboard", action="store_true", help="read from clipboard, translate, and copy result back to clipboard")
    args = p.parse_args(argv)

    try:
        if args.clipboard:
            if pyperclip is None:
                eprint("pyperclip is required for clipboard mode. Install with: pip install pyperclip")
                return 1
            text = pyperclip.paste().strip()
            if not text:
                eprint("Warning: clipboard is empty")
                return 0
            translated = translate_text(text, args.model, args.system_prompt)
            pyperclip.copy(translated)
            print(f"Translated and copied to clipboard: {translated[:50]}...")
            return 0
        if args.dir:
            in_dir = args.dir
            out_dir = args.outdir or os.path.join(in_dir, "_en")
            os.makedirs(out_dir, exist_ok=True)
            files = sorted([f for f in os.listdir(in_dir) if f.lower().endswith(".txt")])
            if not files:
                eprint(f"No .txt files found in {in_dir}")
                return 1
            for fname in files:
                in_path = os.path.join(in_dir, fname)
                base = os.path.splitext(fname)[0]
                out_path = os.path.join(out_dir, base + args.suffix)
                translate_file(in_path, out_path, args.model, args.system_prompt)
            return 0
        # single-file mode
        if args.input and args.output:
            translate_file(args.input, args.output, args.model, args.system_prompt)
            return 0
        # stdin/stdout mode
        if not args.input and not args.output:
            text = sys.stdin.read().strip()
            if not text:
                eprint("Warning: no input text")
                return 0
            translated = translate_text(text, args.model, args.system_prompt)
            print(translated)
            return 0
        p.print_help()
        return 2
    except Exception as exc:
        eprint(f"Error: {exc}")
        return 3


if __name__ == "__main__":
    raise SystemExit(main())
