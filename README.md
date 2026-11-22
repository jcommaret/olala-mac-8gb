# Olala sur un Mac Apple Silicon 8 Go

Recette pour faire tourner [Olala-v1.0-mini-7A1B](https://huggingface.co/OVHaiLLM/Olala-v1.0-mini-7A1B) (OVHcloud, Apache-2.0) en local sur un Mac à **8 Go de RAM**, avec une interface de chat dans le navigateur.

Olala est un modèle hybride (Mamba + attention + MoE, 6,8 B paramètres, ~1 B actifs). Son architecture `olala` n'est pas prise en charge par llama.cpp officiel ni par Ollama : il faut le [fork llama.cpp d'OVH](https://github.com/OVHai-LLM/llama.cpp).

## Installation

```sh
git clone https://github.com/jcommaret/olala-mac-8gb.git && cd olala-mac-8gb
./setup.sh          # clone + compile le fork llama.cpp d'OVH, télécharge le GGUF q5_k_m (6 Go)
./start-llama.sh    # puis ouvrir http://127.0.0.1:8080
```

Prérequis : Xcode Command Line Tools, CMake, git, Node.js (pour compiler l'interface web), ~8 Go de disque.

## Configuration

GGUF **q5_k_m** sur le **CPU**, experts MoE lus à la demande depuis le SSD (`start-llama.sh`) :

```sh
llama-server -m Olala-v1.0-mini-7A1B-q5_k_m.gguf \
  -dev none -ngl 0 --no-op-offload -t 4 -fa on -nr \
  --lazy-mode on --lazy-cache 2G \
  -ctk q8_0 -ctv q8_0 -c 8192 -np 1 --host 127.0.0.1 --port 8080
```

| Option | Rôle |
|---|---|
| `-dev none -ngl 0 --no-op-offload` | tout sur le CPU : sur 8 Go, le modèle ne tient pas dans la mémoire GPU |
| `-t 4` | un thread par cœur performance du M2 |
| `--lazy-mode on --lazy-cache 2G` | les experts MoE restent sur le SSD, 2 Go des plus récents sont gardés en RAM |
| `-fa on -nr -ctk q8_0 -ctv q8_0` | réglages CPU recommandés par OVH (flash attention, pas de repack, KV cache 8 bits) |
| `-c 8192 -np 1` | un utilisateur, 8k tokens de contexte (un prompt plus long que `-c` échoue : le modèle est récurrent) |

## Performances

MacBook Air M2 (4 cœurs P + 4 cœurs E), 8 Go, macOS 27.3, avec d'autres applications ouvertes.

| Mesure | Résultat |
|---|---|
| Lecture du prompt (`llama-bench`, pp256) | ~56 tok/s |
| Génération (`llama-bench`, tg64) | ~15,5 tok/s |
| 1er token, prompt de ~300 tokens | 1–2 s (~8 s à la toute première requête) |
| Génération en usage réel (réponses de 550–700 tokens) | 15,4–15,8 tok/s |
| Mémoire | ~3 Go, pas de swap |

## Utilisation

- **Interface web** : http://127.0.0.1:8080 (raisonnement affiché à part, bouton *Skip reasoning*).
- **API compatible OpenAI** : `http://127.0.0.1:8080/v1`. Paramètre `reasoning_effort` : `none`, `low`, `medium`, `high`.

```sh
curl -s http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "messages": [{"role": "user", "content": "Bonjour !"}],
  "reasoning_effort": "low", "temperature": 0.8, "top_p": 0.9, "top_k": 40
}'
```

Le raisonnement est souvent long : `low` ou `none` donnent des réponses bien plus rapides.

## Crédits

Modèle et fork llama.cpp : OVHcloud / OVH LLM SAS (Apache-2.0, MIT). Ce dépôt ne contient que des scripts, aucun poids ; ils sont sous [licence MIT](LICENSE).
