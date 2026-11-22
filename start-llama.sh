#!/bin/zsh
# Olala q5_k_m with OVH's llama.cpp fork, tuned for an 8 GB Apple Silicon Mac.
# Chat UI + OpenAI-compatible API: http://127.0.0.1:8080   (Ctrl+C to stop)
ROOT="${0:A:h}"
exec "$ROOT/llama.cpp/build/bin/llama-server" \
  -m "$ROOT/gguf/Olala-v1.0-mini-7A1B-q5_k_m.gguf" \
  -dev none -ngl 0 --no-op-offload -t 4 -fa on -nr \
  --lazy-mode on --lazy-cache 2G \
  -ctk q8_0 -ctv q8_0 -c 8192 -np 1 \
  --host 127.0.0.1 --port 8080 "$@"
