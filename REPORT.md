# Smartie — Technical Report

**Team ID:** Smartie (must match the organizer-issued identifier)  
**Domain:** Corporate / Enterprise  
**Model:** Qwen2.5-1.5B-Instruct-Q4_K_M  
**Status:** Gate 1 submitted; repository snapshot archived  
**Devpost:** https://devpost.com/software/smartie  
**Video demo:** https://www.youtube.com/watch?v=t-9x1-0f17Y

## Problem

African micro and small businesses often conduct sales, support, and collections through messaging while operating with intermittent connectivity, limited software budgets, and commodity laptops. A cloud-only assistant can be unavailable at the exact moment an owner needs to answer a customer or organize immediate operating actions. It can also require sending sensitive commercial details to a remote service.

Smartie is deliberately narrow. It turns facts supplied by a business owner into four outputs: a customer reply, low-cost marketing copy, a payment follow-up, or a short operating plan. It does not retrieve live data and does not invent prices, laws, exchange rates, or market statistics. The immediate target is an English-speaking Nigerian microbusiness or independent creator, while the design applies to similar connectivity-constrained businesses across Africa.

African applicability is structural, not decorative: the prompts and system policy preserve supplied currencies such as NGN, favour messaging-ready outputs, assume neither reliable broadband nor paid APIs, and prioritize low-cost actions. The financial-operations pairing is load-bearing because exact balances, costs, dates, and next actions determine the usefulness of payment and operating outputs.

## Design decisions

### Base model and runtime

The baseline uses the official Qwen2.5-1.5B-Instruct GGUF release under Apache-2.0. It runs through `llama.cpp`, as required by the challenge. The 1.5B class was selected as a practical middle point: materially more capable than a 135M demonstration model, but small enough to leave generous RAM headroom on the 8 GB target.

### Quantization

Q4_K_M is approximately 1.12 GB on disk. It was selected as the initial compromise between instruction-following quality and memory/throughput. Q5_K_M may retain somewhat more quality but increases memory and bandwidth; Q3_K_M saves space but risks weaker arithmetic and constraint following. These alternatives have not yet been benchmarked on the participant laptop, so no superiority claim is made.

### Prompt and application design

`smartie.py` is a zero-dependency wrapper around `llama-cli`. A fixed system policy tells the model to use only supplied facts, preserve currency, expose assumptions, and keep output short. Four task policies reduce ambiguity without fine-tuning. Inference is deterministic enough for demonstrations (`temperature=0.2`, seed 42), CPU-only (`-ngl 0`), capped at a 2,048-token context and 220 generated tokens, and limited to at most four threads by default.

The two submitted prompts test different Corporate / Enterprise capabilities. One tests prioritisation and instruction compliance using a Nigerian laundry-business scenario. The other tests tone control, exact factual preservation, and concise customer communication for a Lagos creator. Smartie is intentionally not presented as a financial calculator: informal testing exposed unreliable multi-step arithmetic in this model class, so the Gate 1 scope is operating checklists and business communication.

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
| Qwen2.5 3B Q4_K_M | Potentially better general capability | Informal participant tests fell to roughly 8–9 generation tokens/s and did not improve constraint compliance consistently |
| Fine-tuned 1.5B model | Better domain fit | Not credible before Gate 1 without a curated, licensed dataset and controlled evaluation |

## Benchmarks

The following values come from a complete official ADTC participant-profiler run. The run used WSL1 on Ubuntu 26.04 LTS rather than the organizer's Ubuntu 22.04 audit image, so they are honest participant measurements, not a prediction of final audit hardware performance.

| Metric | Measured value |
|---|---|
| Machine / CPU / OS | Intel Core i5-8250U @ 1.60 GHz / Ubuntu 26.04 LTS under WSL1 |
| Physical RAM | 15.9 GB reported by profiler |
| Peak RSS | 1,704.34 MB (about 1.66 GiB) |
| Steady-state RSS | 1,637.85 MB |
| Generation throughput | 17.98 tokens/s |
| First-token latency | 10,318.51 ms |
| Accuracy | ARC-Easy, 50 samples: 0.74 `acc_norm` |
| Peak CPU temperature | Unavailable in this WSL1 environment (`null`) |
| Thermal throttling | `false` |
| Self-reported performance score (Sperf) | 100.00 |
| Self-reported efficiency score (Seff) | 76.22 |

The profiler reported 1,777,088,000 parameters and confirmed that the declared 1.78B estimate matches. `Sperf` uses the profiler README formula `min(17.98 / 15, 1) × 100`; `Seff` uses `max(0, (7 - (1704.34 / 1024)) / 7) × 100`. The full `submission.json` should be retained with the repository submission artifacts.

## Reproducibility

1. Run `bash download_model.sh`; it downloads the public GGUF and verifies its header.
2. Ensure `llama-cli` and `llama-bench` are on `PATH`.
3. Run `python3 validate_submission.py`.
4. Run `python3 smartie.py payment "..."` for a functional offline test.
5. Run `bash run_profiler.sh` to create `submission.json` on the participant laptop.

Model weights are excluded from Git. Inference contains no network code or external service dependency.

## Gate 1 closure

Smartie was submitted to the Africa Deep Tech Challenge 2026 with the two prompts recorded in `metadata.json` and `submission.json`. The profiler artifact is retained unchanged as the evidence from the participant-laptop run.

Known limitation: Smartie's small local model is scoped to constrained business writing and operating checklists. Numerical results and any legal, accounting, medical, or financial content require human verification.

Potential work after organizer feedback includes Android feasibility research, deterministic output validation, a simpler user interface, and a physical Ubuntu 22.04 / 8 GB retest. These future changes are outside the archived Gate 1 snapshot.
