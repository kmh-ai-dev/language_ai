#!/usr/bin/env bash

# setup_qwen.sh - install Ollama and pull Qwen2.5 model on macOS/Linux
#
# This convenience script performs the following tasks:
#   1. Detects the host OS (macOS or Linux)
#   2. Installs Ollama using Homebrew (if present) or the official
#      installer script
#   3. Verifies that the `ollama` command is usable and prints its
#      version
#   4. Starts the Ollama server in the background if not already running
#   5. Downloads the Qwen2.5:7b model (or skips if already present)
#   6. Optionally installs/upgrades the Python `ollama` client library
#   7. Writes a small example translator script (`translate.py`) if
#      one does not already exist
#
# After execution you can immediately test the setup with commands like
#   ollama run qwen2.5:7b "안녕하세요를 영어로 번역해주세요"
# and use Python examples from the accompanying documentation.
#
# Usage:
#   bash setup_qwen.sh
#   chmod +x setup_qwen.sh && ./setup_qwen.sh

set -euo pipefail

# exit on error, treat unset variables as error, propagate failures in pipes

# prevent accidental keystrokes from being interpreted by this script.
# a stray word such as "on" (which the shell would otherwise try to execute)
# can show up in the log if you type while a long-running command is active.
# closing stdin and defining a no-op "on" function avoids that noise.
exec </dev/null
on() { :; }

echo "[setup] starting environment preparation for Qwen 2.5..."

# determine platform so we know which installer to run
OS_TYPE=$(uname | tr '[:upper:]' '[:lower:]')

# installation helper for macOS; prefers Homebrew if available
install_ollama_mac() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew found. Installing Ollama via brew..."
        # "|| true" avoids script exit if brew says it's already installed
        brew install ollama || true
    else
        echo "Homebrew is not installed. Trying to install Ollama via curl script..."
        # fallback to official shell installer
        curl -fsSL https://ollama.com/install.sh | sh
    fi
}

# linux installer uses the same curl script; no brew on most distros
install_ollama_linux() {
    echo "Installing Ollama via official install script..."
    curl -fsSL https://ollama.com/install.sh | sh
}

# run the appropriate installer based on detected OS
# (the earlier `on()` function will absorb any stray "on" here too)
case "$OS_TYPE" in
    darwin*)
        install_ollama_mac
        ;;
    linux*)
        install_ollama_linux
        ;;
    *)
        # other platforms are not officially supported by this script
        echo "Unsupported OS: $OS_TYPE. You may need to install Ollama manually." >&2
        ;;
esac

# after installing, verify the `ollama` binary can be invoked
if ! command -v ollama >/dev/null 2>&1; then
    echo "ollama command not found after installation. Please check your PATH." >&2
    exit 1
fi

# show version information to confirm installation succeeded
echo "ollama version: $(ollama version || echo 'unknown')"

# Ollama provides a local server; start it if it's not already running
# `ollama ps` returns an error code if no containers are up
if ! ollama ps >/dev/null 2>&1; then
    echo "Starting ollama server in background..."
    ollama serve &
    # give the service a moment to spin up before pulling models
    sleep 2
fi

# download the Qwen 2.5 model variant we want to use
# adjust MODEL_NAME if you prefer 3b or 14b later
MODEL_NAME="qwen2.5:7b"
if ollama list | grep -q "${MODEL_NAME}"; then
    echo "Model ${MODEL_NAME} already pulled."
else
    echo "Downloading ${MODEL_NAME} (this may take a while)..."
    ollama pull ${MODEL_NAME}
fi

# if Python3 is available, install or upgrade the Python client library
# so the example scripts can import `ollama`
if command -v python3 >/dev/null 2>&1; then
    echo "Installing Python client 'ollama' via pip3..."
    python3 -m pip install --upgrade ollama || true
fi

# create a small translate.py example if not exists
SCRIPT="translate.py"
if [[ ! -f "$SCRIPT" ]]; then
    cat <<'EOF' > "$SCRIPT"
#!/usr/bin/env python3
import ollama

def translate_ko_to_en(korean_text):
    response = ollama.chat(
        model='qwen2.5:7b',
        messages=[
            {'role': 'system', 'content': 'You are a professional translator. Translate Korean to English accurately.'},
            {'role': 'user', 'content': f'Translate the following Korean text to English:\n\n{korean_text}'}
        ]
    )
    return response['message']['content']

if __name__ == '__main__':
    import sys
    if len(sys.argv) != 3:
        print('usage: python3 translate.py input_kr.txt output_en.txt')
        sys.exit(1)
    inp, out = sys.argv[1], sys.argv[2]
    with open(inp, 'r', encoding='utf-8') as f:
        txt = f.read()
    with open(out, 'w', encoding='utf-8') as f:
        f.write(translate_ko_to_en(txt))
    print(f'Converted {inp} -> {out}')
EOF
    chmod +x "$SCRIPT"
    echo "Created example script $SCRIPT"
fi


echo "[setup] finished. You can now use Qwen 2.5 with Ollama."

echo "Try: ollama run qwen2.5:7b \"안녕하세요를 영어로 번역해주세요\""
