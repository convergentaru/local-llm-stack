# Qwen3.6-35B-A3B — local experiment

## Model

- File: `/home/oleg/models/Qwen3.6-35B-A3B-UD-IQ2_XXS.gguf`
- Parameters: 34,660,610,688
- Architecture: MoE
- Quantization: IQ2_XXS
- Bits per weight: 2.0625 bpw
- GGUF size: 10,745,596,416 bytes
- Native training context: 262,144 tokens

## Runtime

- llama.cpp: `/home/oleg/llama.cpp/build-cublas/bin/llama-server`
- Context: 4096
- GPU layers: 999
- Flash Attention: enabled
- Jinja: enabled
- Host: `127.0.0.1`
- Port: `8999`
- API alias: `qwen3.6-35b-experiment`

## Reproduction

```bash
./run.sh
```

## API

`http://127.0.0.1:8999/v1`

## Benchmark

The model was tested on adversarial software-engineering tasks involving asynchronous race conditions, stale responses, AbortController cancellation, JavaScript closures, mutable state ownership, monotonic request IDs, and production-quality concurrency reasoning.

### Preliminary result

The model correctly identified the ownership/closure problem with a shared mutable AbortController and understood that a request-specific local controller must be captured by the closure.

Limitation: the model did not preserve the original production architecture exactly and rewrote part of the example instead of making the minimal correction. It also made an inaccurate reference to garbage collection.

Conclusion: promising coding/reasoning capability, but concurrency-heavy production code still requires adversarial review.

## References

### ExVRAM

GitHub profile supplied as a reference for the Qwen3.6/large-model local inference work:

https://github.com/ExVRAM

### AirLLM

Hugging Face article:

https://huggingface.co/blog/lyogavin/airllm

AirLLM demonstrates layer-wise inference, where model layers are loaded and executed sequentially to reduce GPU memory requirements. This is a related large-model inference technique, not the runtime used by this experiment.

AirLLM source:

https://github.com/lyogavin/Anima/tree/main/air_llm

### Qwen3.6-35B-A3B

Current vLLM recipe:

https://github.com/vllm-project/recipes/blob/main/models/Qwen/Qwen3.6-35B-A3B.yaml

The recipe documents the 35B total / 3B active MoE architecture and current deployment variants.

## Important

This experiment uses the exact local configuration documented above. Do not replace it with another quantization or inference backend without recording the change separately.
