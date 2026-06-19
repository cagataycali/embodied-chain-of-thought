# 🧠🤖 Embodied Chain-of-Thought (ECoT)

> Capture not just *what* a robot did (VLA: vision→action) but *why* it
> decided to — the language reasoning + tool calls of the agent(s) driving it —
> **time-aligned to a LeRobot video spine**, contributed **continuously and
> concurrently by multiple agents**.

ECoT is a **dataset specification** + reference tooling that binds free-form
agent reasoning traces to a dense robot-control corpus, so a single canonical
store materializes **two views**:

1. **VLA view** — raw [LeRobot v3](https://github.com/huggingface/lerobot)
   (`front video + state + action @ fps`). Train OpenVLA / π0 / GR00T / SmolVLA.
2. **ECoT view** — ChatML with native tool-call tokens + **frame references**
   (not duplicated base64), aligned step-by-step to the trajectory.

The ECoT training target:

> *Given frames up to time `t` and reasoning-so-far → predict the next
> reasoning step **and** the next action chunk.*

---

## Why

Pure VLA datasets are mute: they show the motor babble but throw away the
*intent*. Meanwhile, agentic robot stacks (e.g. [Strands](https://github.com/strands-agents)
agents driving an Earth Rover Mini) emit rich reasoning every turn —
`system prompt → text → toolUse → toolResult → … → assistant` — and today that
structure is discarded.

ECoT keeps both, and **joins them on a single equation**:

```
frame_index = round((wall_clock_ts − episode_start_ts) × fps)
```

Events are *sparse*; frames are *dense*; they meet at `frame_index`.

---

## Repository layout

```
spec/           # the normative specification (versioned)
  00-overview.md
  01-event-taxonomy.md
  02-frame-binding.md
  03-multi-agent.md
  04-chatml-view.md
  05-conformance.md
schema/         # machine-readable schemas
  reasoning_events.sql      # canonical SQLite schema (WAL, multi-writer)
  ecot_sample.schema.json   # JSON Schema for an ECoT training sample
examples/
  ecot_sample.json          # a minimal, valid ECoT sample
```

## Prior art we anchor on

| Source | What we borrow |
|---|---|
| **RLDS / Open-X-Embodiment** (2023) | step-aligned trajectory schema; per-step `language_instruction`; multi-embodiment standard |
| **Embodied Chain-of-Thought** (Zawalski et al., 2024) | reasoning text aligned to trajectory steps; *reason-then-act* target — **our core idea** |
| **LeRobot v3** (HF) | the dense frame spine: `episode_index`, `frame_index`, `timestamp`, video + parquet |
| **HF chat templates w/ tools** | canonical render of `system + tools + messages` → native `<tool_call>` tokens (Qwen3 / Llama 3.1) |

## Status

`spec v0.1` — draft. Reference implementation lives in
[`earth-rover-mini`](https://github.com/cagataycali/earth-rover-mini)
(`tools/reasoning_log.py` writer + `tools/ecot_export.py` exporter).

## License

MIT
