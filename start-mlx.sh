#!/bin/zsh
# Lance le serveur Olala (MLX, q4e8) et la page de chat locale.
# Puis ouvre http://127.0.0.1:8080 dans ton navigateur. Ctrl+C arrête les deux.
set -e
ROOT="${0:A:h}"
export MLX_ENGINE_API_KEY="${MLX_ENGINE_API_KEY:-une-cle}"
# Sur un Mac M1, décommente la ligne suivante :
# export OLALA_MOE_V3=0

cd "$ROOT/mlx-engine"
.venv/bin/python -m mlx_engine.server --model ./olala-mlx/q4e8 \
  --host 127.0.0.1 --port 8000 --context-length 8192 --parallel-sessions 1 &
MLX_PID=$!
trap 'kill $MLX_PID 2>/dev/null' EXIT INT TERM

.venv/bin/python "$ROOT/web/serve.py"
