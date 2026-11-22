#!/bin/zsh
# Olala q5_k_m via le fork llama.cpp d'OVH, réglé pour un Mac M2 8 Go :
#  - CPU uniquement (sur GPU il faut le bf16 et >= 16 Go ; le q5_k_m n'y tient pas)
#  - 4 threads = les 4 cœurs performance (plus = plus lent)
#  - lazy-mode : les experts MoE sont lus depuis le SSD, 2 Go gardés en RAM
#    (1 Go : ~11 tok/s, 2 Go : ~15,5 tok/s, 3 Go : pas mieux et ça swappe)
# Interface de chat + API OpenAI : http://127.0.0.1:8080   (Ctrl+C pour arrêter)
ROOT="${0:A:h}"
exec "$ROOT/llama.cpp/build/bin/llama-server" \
  -m "$ROOT/gguf/Olala-v1.0-mini-7A1B-q5_k_m.gguf" \
  -dev none -ngl 0 --no-op-offload -t 4 -fa on -nr \
  --lazy-mode on --lazy-cache 2G \
  -ctk q8_0 -ctv q8_0 -c 8192 -np 1 \
  --host 127.0.0.1 --port 8080 "$@"
