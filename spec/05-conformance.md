# ECoT Spec §5 — Conformance

An implementation is **ECoT v0.1 conformant** if:

## Writer
- [ ] Persists events to a store matching `schema/reasoning_events.sql`
      (columns + indexes), or a faithful superset.
- [ ] Tolerates ≥3 concurrent writer processes without corruption (WAL).
- [ ] Computes `frame_index` per §2 when an episode is active; emits `NULL`
      otherwise.
- [ ] Emits `frame_span_lo/hi` for span tools (motion) per §2.
- [ ] SHOULD log per-frame `action_age` (seconds since the command was issued)
      so transition/smeared frames are filterable (§2).
- [ ] Stores images as references (§2), never base64.
- [ ] Never raises into the driving agent on logging failure.
- [ ] Records per-session context (system prompt + tool specs + model_id).
- [ ] Records `episode_anchors` on episode start/stop.

## Exporter
- [ ] Produces a sample validating against `schema/ecot_sample.schema.json`.
- [ ] Merges consecutive assistant tool_use into one `tool_calls` array.
- [ ] Preserves `tool_use_id` → `tool_call_id`.
- [ ] Attaches `_meta {agent_id, frame_index, t, frame_span?}` per message.
- [ ] Pulls `action_chunks` from the LeRobot parquet by `frame_span`
      (or degrades gracefully with a `note` when parquet/pandas absent).
- [ ] Exports the ambient track (`episode_index = NULL`) on demand.

## Determinism
- [ ] Given a fixed `events.sqlite`, export is byte-stable modulo timestamps.
