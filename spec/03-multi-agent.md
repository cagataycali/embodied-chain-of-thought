# ECoT Spec §3 — Multi-Agent & Ambient Reasoning

Multiple agents drive the same embodiment concurrently. Every event tags:
- `agent_id` ∈ {`main`, `thinker`, `telegram`, `voice`, …}
- `session_id` — one agent run/turn (UUID-suffixed)

## Episode-bound agents
`main` / `telegram` / `voice` run *inside* an auto-record episode → their
events bind to that episode's frames.

## The ambient track (`thinker`)
An ambient agent (e.g. a 60s thinker loop) may run between tasks with no active
episode. Two modes:
- **Episode live** → bind to current episode (`episode_index = current`).
- **Idle** → write to a **global ambient track** (`episode_index = NULL`, still
  timestamped). Ambient reasoning is the robot "thinking" between tasks and is
  valuable; keep it separate and optionally splice into the nearest episode at
  export time.

This realizes *continuous, concurrent contribution*: every agent, every cycle,
appends to the same `events.sqlite`.
