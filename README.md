# Olala on an 8 GB Apple Silicon Mac

A recipe to run [Olala-v1.0-mini-7A1B](https://huggingface.co/OVHaiLLM/Olala-v1.0-mini-7A1B) (OVHcloud, Apache-2.0) locally on a Mac with **8 GB of RAM**, with a chat interface in the browser.

Olala is a hybrid model (Mamba + attention + MoE, 6.8B parameters, ~1B active). Its `olala` architecture is not supported by upstream llama.cpp or Ollama: you need [OVH's llama.cpp fork](https://github.com/OVHai-LLM/llama.cpp).

## Installation

```sh
git clone https://github.com/jcommaret/olala-mac-8gb.git && cd olala-mac-8gb
./setup.sh          # clones and builds OVH's llama.cpp fork, downloads the q5_k_m GGUF (6 GB)
./start-llama.sh    # then open http://127.0.0.1:8080
```

Requirements: Xcode Command Line Tools, CMake, git, Node.js (to build the web UI), ~8 GB of free disk space.

## Configuration

**q5_k_m** GGUF on the **CPU**, with MoE experts read on demand from the SSD (`start-llama.sh`):

```sh
llama-server -m Olala-v1.0-mini-7A1B-q5_k_m.gguf \
  -dev none -ngl 0 --no-op-offload -t 4 -fa on -nr \
  --lazy-mode on --lazy-cache 2G \
  -ctk q8_0 -ctv q8_0 -c 8192 -np 1 --host 127.0.0.1 --port 8080
```

| Option | Purpose |
|---|---|
| `-dev none -ngl 0 --no-op-offload` | everything on the CPU: with 8 GB, the model does not fit in GPU memory |
| `-t 4` | one thread per M2 performance core |
| `--lazy-mode on --lazy-cache 2G` | MoE experts stay on the SSD; the 2 GB most recently used are kept in RAM |
| `-fa on -nr -ctk q8_0 -ctv q8_0` | CPU settings recommended by OVH (flash attention, no repacking, 8-bit KV cache) |
| `-c 8192 -np 1` | one user, 8k-token context (a prompt longer than `-c` fails: the model is recurrent) |

## Performance

MacBook Air M2 (4 P-cores + 4 E-cores), 8 GB, macOS 27.3, with other applications open.

| Metric | Result |
|---|---|
| Prompt processing (`llama-bench`, pp256) | ~56 tok/s |
| Generation (`llama-bench`, tg64) | ~15.5 tok/s |
| Time to first token, ~300-token prompt | 1–2 s (~8 s on the very first request) |
| Generation in real use (550–700-token answers) | 15.4–15.8 tok/s |
| Memory | ~3 GB, no swapping |

## Usage

- **Web UI**: http://127.0.0.1:8080 (reasoning shown separately, *Skip reasoning* button).
- **OpenAI-compatible API**: `http://127.0.0.1:8080/v1`. `reasoning_effort` parameter: `none`, `low`, `medium`, `high`.

```sh
curl -s http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "messages": [{"role": "user", "content": "Hello!"}],
  "reasoning_effort": "low", "temperature": 0.8, "top_p": 0.9, "top_k": 40
}'
```

Reasoning is often long: `low` or `none` give much faster answers.

## Credits

Model and llama.cpp fork: OVHcloud / OVH LLM SAS (Apache-2.0, MIT). This repository only contains scripts, no weights; they are under the [MIT license](LICENSE).
