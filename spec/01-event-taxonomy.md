# ECoT Spec §1 — Event Taxonomy

Each agent turn yields a `messages` list of ContentBlocks. We emit **one event
per atomic block**, at the wall-clock instant it occurs.

| `type` | `role` | payload | frame binding |
|---|---|---|---|
| `user_input`    | user      | prompt text (+ image_refs) | frame at input time |
| `reasoning`     | assistant | text block (CoT / narration) | frame at emit time |
| `tool_use`      | assistant | `{name, input, tool_use_id}` | **span** for motion; instant otherwise |
| `tool_result`   | user      | `{tool_use_id, text, image_refs}` | frame at result time |
| `assistant_end` | assistant | final text reply | frame at end |

## Ordering
- `seq` — monotonic order **within** a turn (0,1,2,…).
- `turn_index` — increments per agent invocation.
- `(wall_ts, seq)` is the canonical sort key for export.

## Correlation
- `tool_use_id` correlates a `tool_use` with its later `tool_result`
  (→ OpenAI `tool_call_id`).

## Content rules
- Text blocks → `text`.
- Image blocks → dereferenced into `image_refs` (see §2); `text` may be
  `"[image]"` as a placeholder.
- Tool input → `tool_input` (JSON of `toolUse.input`).
