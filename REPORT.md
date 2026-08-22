# Smartie — Technical Report

**Team ID:** pending registered-team metadata  
**Domain:** Corporate / Enterprise  
**Model:** Qwen2.5-1.5B-Instruct-Q4_K_M  
**Status:** Gate 1 baseline; hardware telemetry pending

## Problem

African micro and small businesses often conduct sales, support, and collections through messaging while operating with intermittent connectivity, limited software budgets, and commodity laptops. A cloud-only assistant can be unavailable at the exact moment an owner needs to answer a customer or reason over a few operating figures. It can also require sending sensitive commercial details to a remote service.

Smartie is deliberately narrow. It turns facts supplied by a business owner into four outputs: a customer reply, low-cost marketing copy, a payment follow-up, or a short operating plan. It does not retrieve live data and does not invent prices, laws, exchange rates, or market statistics. The immediate target is an English-speaking Nigerian microbusiness or independent creator, while the design applies to similar connectivity-constrained businesses across Africa.

African applicability is structural, not decorative: the prompts and system policy preserve supplied currencies such as NGN, favour messaging-ready outputs, assume neither reliable broadband nor paid APIs, and prioritize low-cost actions. The financial-operations pairing is load-bearing because exact balances, costs, dates, and next actions determine the usefulness of payment and operating outputs.

## Design decisions

### Base model and runtime

The baseline uses the official Qwen2.5-1.5B-Instruct GGUF release under Apache-2.0. It runs through `llama.cpp`, as required by the challenge. The 1.5B class was selected as a practical middle point: materially more capable than a 135M demonstration model, but small enough to leave generous RAM headroom on the 8 GB target.

### Quantization

Q4_K_M is approximately 1.12 GB on disk. It was selected as the initial compromise between instruction-following quality and memory/throughput. Q5_K_M may retain somewhat more quality but increases memory and bandwidth; Q3_K_M saves space but risks weaker arithmetic and constraint following. These alternatives have not yet been benchmarked on the participant laptop, so no superiority claim is made.

### Prompt and application design

`smartie.py` is a zero-dependency wrapper around `llama-cli`. A fixed system policy tells the model to use only supplied facts, preserve currency, expose assumptions, keep output short, and check arithmetic. Four task policies reduce ambiguity without fine-tuning. Inference is deterministic enough for demonstrations (`temperature=0.2`, seed 42), CPU-only (`-ngl 0`), capped at a 2,048-token context and 220 generated tokens, and limited to at most four threads by default.

The two submitted prompts test different Corporate / Enterprise capabilities. One tests arithmetic, prioritisation, and instruction compliance using a Nigerian laundry-business scenario. The other tests tone control, exact factual preservation, and concise customer communication for a Lagos creator. Hidden prompts remain important; the assistant policy is generic rather than tailored only to the two visible prompts.

## Constraints

- Evaluation target: four vCPUs, 8 GB RAM, integrated graphics, Ubuntu 22.04.
- Profiler efficiency uses a 7 GB RAM budget; OOM or sandbox failure disqualifies the entry.
- Inference must be completely offline. Only the pre-run model download uses a network connection.
- The model and application cannot assume stable broadband, cloud APIs, or paid subscriptions.
- CPU throughput and thermals matter, so outputs and context are bounded and GPU offload is disabled for audit parity.
- A 1.5B general instruct model can still make arithmetic or factual mistakes. Smartie requires supplied facts, shows assumptions, and is not positioned as professional legal, accounting, medical, or financial advice.

## Alternatives considered

| Option | Potential benefit | Reason not selected for baseline |
|---|---|---|
| SmolLM2 135M | Very high throughput and very low RAM | Quality risk is too high for multi-constraint business responses |
| Qwen2.5 0.5B | Faster and smaller | Likely weaker arithmetic, planning, and tone control |
| Qwen2.5 1.5B Q5_K_M | Possible quality retention | Must justify extra memory/bandwidth with measured output gains |
| 3B–4B Q4 model | Better general capability | Lower CPU throughput and less thermal/RAM margin |
| Fine-tuned 1.5B model | Better domain fit | Not credible before Gate 1 without a curated, licensed dataset and controlled evaluation |

## Benchmarks

No hardware-dependent results are claimed yet. The model has not been profiled on the submitter's intended laptop, and fabricated or cross-machine figures would be misleading.

Run the official participant profiler and replace only the `PENDING` cells below with values from `submission.json`:

| Metric | Measured value |
|---|---|
| Machine / CPU / OS | PENDING — participant to record |
| Physical RAM | PENDING — participant to record |
| Peak RSS | PENDING — `memory.peak_rss_mb` |
| Steady-state RSS | PENDING — `memory.steady_state_rss_mb` |
| Generation throughput | PENDING — `throughput.tokens_per_second_generation` |
| First-token latency | PENDING — `throughput.first_token_latency_ms` |
| Peak CPU temperature | PENDING — profiler thermal block |
| Thermal throttling | PENDING — profiler thermal block |

The final Gate 1 run must be performed with the official ADTC profiler in participant mode. A smoke run may use `--skip-accuracy`; the retained final telemetry should come from a full run. Devpost's self-reported performance and efficiency fields must be computed from the organizer's current formulas and entered as separate plain numbers.

## Reproducibility

1. Run `bash download_model.sh`; it downloads the public GGUF and verifies its header.
2. Ensure `llama-cli` and `llama-bench` are on `PATH`.
3. Run `python3 validate_submission.py`.
4. Run `python3 smartie.py payment "..."` for a functional offline test.
5. Run `bash run_profiler.sh` to create `submission.json` on the participant laptop.

Model weights are excluded from Git. Inference contains no network code or external service dependency.


