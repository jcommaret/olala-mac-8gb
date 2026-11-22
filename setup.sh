#!/bin/zsh
# Installe Olala-v1.0-mini-7A1B (q5_k_m) avec le fork llama.cpp d'OVH, compilé pour Apple Silicon.
# Prérequis : Xcode Command Line Tools, CMake, git, Node.js (pour l'interface web), ~8 Go libres.
# Ensuite : ./start-llama.sh puis http://127.0.0.1:8080
set -e
ROOT="${0:A:h}"
cd "$ROOT"

FORK=https://github.com/OVHai-LLM/llama.cpp.git
COMMIT=55c22dca0c987f247c21b427c3b3a09e1a28187f   # version testée
REPO=OVHaiLLM/Olala-v1.0-mini-7A1B-GGUF
FILE=Olala-v1.0-mini-7A1B-q5_k_m.gguf

# 1. Fork llama.cpp d'OVH (le llama.cpp officiel ne connaît pas l'architecture "olala")
if [ ! -d llama.cpp ]; then
  git clone "$FORK" llama.cpp
fi
git -C llama.cpp checkout -q "$COMMIT" 2>/dev/null || echo "(commit $COMMIT introuvable, on garde la branche par défaut)"

# 2. Compilation. L'interface web est construite depuis les sources du fork (npm) :
#    l'interface précompilée téléchargée par défaut ne correspond pas au fork et fait échouer le build.
cmake -S llama.cpp -B llama.cpp/build -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_CURL=OFF -DLLAMA_BUILD_UI=ON -DLLAMA_USE_PREBUILT_UI=OFF
cmake --build llama.cpp/build -j --target llama-server llama-bench

# 3. Poids q5_k_m (6 Go) depuis Hugging Face
mkdir -p gguf
if [ ! -f "gguf/$FILE" ]; then
  if command -v hf >/dev/null; then
    hf download "$REPO" "$FILE" --local-dir gguf
  else
    curl -L --fail -o "gguf/$FILE" "https://huggingface.co/$REPO/resolve/main/$FILE"
  fi
fi

echo "OK. Lance ./start-llama.sh puis ouvre http://127.0.0.1:8080"
