# Olala sur un Mac Apple Silicon 8 Go

Recette pour faire tourner [Olala-v1.0-mini-7A1B](https://huggingface.co/OVHaiLLM/Olala-v1.0-mini-7A1B) (OVHcloud, Apache-2.0) en local sur un Mac à **8 Go de RAM**, avec une interface de chat dans le navigateur.

Olala est un modèle hybride (Mamba + attention + MoE, 6,8 B paramètres, ~1 B actifs). Son architecture `olala` n'est **pas** prise en charge par llama.cpp officiel, Ollama, LM Studio ou mlx-lm : il faut les forks d'OVH.

## TL;DR

```sh
git clone https://github.com/jcommaret/olala-mac-8gb.git && cd olala-mac-8gb
./setup.sh          # clone + compile le fork llama.cpp d'OVH, télécharge le GGUF q5_k_m (6 Go)
./start-llama.sh    # puis ouvrir http://127.0.0.1:8080
```

Prérequis : Xcode Command Line Tools, CMake, git, Node.js (pour compiler l'interface web), ~8 Go de disque.

## Résultats mesurés (MacBook M2, 8 Go)

| Configuration | 1er token | Génération | Remarque |
|---|---|---|---|
| MLX q4e8 sur GPU (`mlx-engine` d'OVH) | 45–65 s | 8–55 tok/s, très irrégulier | 5,3 Go bloqués sur le GPU → le système swappe |
| llama.cpp q5_k_m sur GPU (Metal) | — | — | `Insufficient Memory` : ne tient pas |
| llama.cpp CPU, 8 threads, lazy | — | ~5 tok/s | les cœurs E ralentissent |
| llama.cpp CPU, 4 threads, lazy, cache 1 Go | 1–2 s | ~11 tok/s | |
| **llama.cpp CPU, 4 threads, lazy, cache 2 Go** | **1–2 s** | **~15 tok/s** | **retenu**, pas de swap |
| llama.cpp CPU, 4 threads, lazy, cache 3 Go | 1–2 s | ~15–16 tok/s | pas mieux, le swap remonte |

Prompt de ~300 tokens, réponses de 150 à 700 tokens. En appel direct (sans serveur) MLX atteint ~38 tok/s en génération, mais l'attente du premier token rend l'usage interactif pénible sur 8 Go.

## Pourquoi ces réglages

- **CPU plutôt que GPU** : sur Metal, OVH recommande les poids bf16 (12,7 Go, il faut ≥ 16 Go) ; les GGUF quantifiés peuvent y produire des NaN, et le q5_k_m ne tient de toute façon pas dans la mémoire GPU d'un Mac 8 Go.
- **`-t 4`** : un thread par cœur performance du M2. Au-delà, les cœurs efficacité ralentissent tout.
- **`--lazy-mode on --lazy-cache 2G`** : les experts MoE (82 % du fichier) restent sur le SSD, seuls les plus récents (2 Go) sont gardés en RAM. Le processus tient en ~3 Go au lieu de ~6.
- **`-nr`** (pas de repack), **`-fa on`**, **KV cache `q8_0`** : recommandations d'OVH pour le CPU.
- **`-c 8192 -np 1`** : un seul utilisateur, contexte modeste (un modèle récurrent ne peut pas faire glisser son contexte : un prompt plus long que `-c` échoue).

Tout est dans [`start-llama.sh`](start-llama.sh). Sur une machine avec ≥ 16 Go, suivre plutôt la doc d'OVH (bf16 sur GPU, bien plus rapide).

## Utilisation

- **Interface web** : http://127.0.0.1:8080 (raisonnement affiché à part, bouton *Skip reasoning*).
- **API compatible OpenAI** : `http://127.0.0.1:8080/v1` (utilisable avec Open WebUI, etc.). Paramètre `reasoning_effort` : `none`, `low`, `medium`, `high`.

```sh
curl -s http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "messages": [{"role": "user", "content": "Bonjour !"}],
  "reasoning_effort": "low", "temperature": 0.8, "top_p": 0.9, "top_k": 40
}'
```

Le raisonnement est souvent long : `low` ou `none` donnent des réponses bien plus rapides.

## Variante MLX (pour référence)

Le dossier [`web/`](web/) et [`start-mlx.sh`](start-mlx.sh) servent la version MLX q4e8 (experts 4 bits, reste 8 bits) via le fork [`mlx-engine`](https://github.com/OVHai-LLM/mlx-engine) d'OVH (testé au commit `58083ca`). Ce serveur n'a ni interface web ni CORS, n'accepte que `stream: true` et exige `temperature` et `top_k` : `web/serve.py` est un petit proxy (bibliothèque standard Python) qui sert une page de chat et ajoute la clé d'API.

Installation :

```sh
git clone https://github.com/OVHai-LLM/mlx-engine.git && cd mlx-engine
uv venv --python 3.11 .venv && uv pip install --python .venv/bin/python -r requirements.txt
.venv/bin/hf download OVHaiLLM/Olala-v1.0-mini-7A1B-MLX --include "q4e8/*" --local-dir ./olala-mlx
cd .. && ./start-mlx.sh   # http://127.0.0.1:8080
```

Sur 8 Go, c'est la voie la moins agréable (voir le tableau). Sur Mac M1 : `export OLALA_MOE_V3=0`.

## Pourquoi pas un GGUF 4 bits ?

OVH ne publie pas de Q4 GGUF (retiré). La doc du fork décrit une variante 4,0 Go pour les machines 8 Go, à fabriquer soi-même depuis le bf16 (13,6 Go à télécharger + matrice d'importance + quantification, 1 à 2 h sur un M2). Sur CPU, OVH mesure la même vitesse qu'en q5_k_m pour une qualité un peu moindre ; avec le mode lazy, le gain mémoire n'est plus décisif.

## Crédits

Modèle, forks llama.cpp et mlx-engine : OVHcloud / OVH LLM SAS (Apache-2.0, MIT). Ce dépôt ne contient que des scripts et une page de chat ; aucun poids.
