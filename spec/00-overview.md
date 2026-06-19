# ECoT Spec §0 — Overview

**Version:** 0.1 (draft) · **Status:** active

## Goal
Bind sparse, timestamped agent **reasoning** to a dense **LeRobot v3** robot
trajectory, producing one canonical store and two derived views (VLA + ECoT).

## Conceptual model
```
datasets/<repo>/
├── data/            ┐
├── videos/          ├─ UNTOUCHED LeRobot v3  → VLA view
├── meta/            ┘     (front mp4 + state + action @ fps)
├── audio/                 (optional WAV sidecars)
└── reasoning/        ← ECoT: sparse, timestamped agent reasoning
    ├── events.sqlite              ← canonical cross-process event log (WAL)
    ├── episode_000007.jsonl       ← per-episode raw export (one event/line)
    └── episode_000007.ecot.json   ← materialized ChatML training sample
```

## The bridge equation
For any agent event emitted at wall-clock `T` while episode `e` is recording
with start time `start_e` and frame rate `fps`:
```
frame_index = round((T − start_e) × fps)
```
- Events are **sparse** (emitted only when the agent reasons/acts).
- Frames are **dense** (emitted every 1/fps seconds by the recorder).
- They meet at `frame_index`. This single equation is the entire spec's core.

## Design invariants (MUST)
1. **Additive.** ECoT logging MUST NOT modify the dense recorder's output.
2. **Dereference, never duplicate.** Image content in reasoning MUST be stored
   as a frame *reference* (`observation.images.front#frame=N`), never base64.
3. **Multi-writer safe.** The event store MUST tolerate ≥3 concurrent writers
   in separate processes (SQLite WAL, one connection per thread).
4. **Best-effort.** A logging failure MUST NOT raise into the driving agent.
5. **Reconcilable.** Events emitted with no active episode (`episode_index =
   NULL`) MUST be reconcilable at export time against `episode_anchors`.
6. **Action provenance.** The recorder SHOULD log per-frame `action_age` so
   consumers can distinguish actively-commanded frames from idle/transition
   ones (see §2).
