#!/bin/zsh
# Installs Olala-v1.0-mini-7A1B (q5_k_m) with OVH's llama.cpp fork, built for Apple Silicon.
# Requirements: Xcode Command Line Tools, CMake, git, Node.js (for the web UI), ~8 GB free.
# Then: ./start-llama.sh and open http://127.0.0.1:8080
set -e
ROOT="${0:A:h}"
cd "$ROOT"

FORK=https://github.com/OVHai-LLM/llama.cpp.git
COMMIT=55c22dca0c987f247c21b427c3b3a09e1a28187f   # tested version
REPO=OVHaiLLM/Olala-v1.0-mini-7A1B-GGUF
FILE=Olala-v1.0-mini-7A1B-q5_k_m.gguf

# 1. OVH's llama.cpp fork (upstream llama.cpp does not know the "olala" architecture)
if [ ! -d llama.cpp ]; then
  git clone "$FORK" llama.cpp
fi
git -C llama.cpp checkout -q "$COMMIT" 2>/dev/null || echo "(commit $COMMIT not found, keeping the default branch)"

# 2. Build. The web UI is built from the fork's sources (npm):
#    the prebuilt UI downloaded by default does not match the fork and breaks the build.
cmake -S llama.cpp -B llama.cpp/build -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_CURL=OFF -DLLAMA_BUILD_UI=ON -DLLAMA_USE_PREBUILT_UI=OFF
cmake --build llama.cpp/build -j --target llama-server llama-bench

# 3. q5_k_m weights (6 GB) from Hugging Face
mkdir -p gguf
if [ ! -f "gguf/$FILE" ]; then
  if command -v hf >/dev/null; then
    hf download "$REPO" "$FILE" --local-dir gguf
  else
    curl -L --fail -o "gguf/$FILE" "https://huggingface.co/$REPO/resolve/main/$FILE"
  fi
fi

echo "Done. Run ./start-llama.sh and open http://127.0.0.1:8080"
