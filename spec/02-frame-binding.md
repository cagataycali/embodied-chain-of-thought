# ECoT Spec §2 — Frame Binding

## Instant binding
Most events bind to a single frame:
```
frame_index = round((wall_ts − episode_start_ts) × fps)
t_in_episode = wall_ts − episode_start_ts
```

## Span binding (actions)
An action that lasts `duration` seconds binds to a **frame range**, because it
*causes* that range of frames:
```
frame_span_lo = round((t_call            − start) × fps)
frame_span_hi = round((t_call + duration − start) × fps)
```

### Per-tool rules (reference embodiment: Earth Rover Mini)
| tool | binding |
|---|---|
| `rover_see` / `rover_screenshot` | frame at **call start** — what the model *saw* when deciding |
| `rover_move` | **span** `[t_call, t_call + duration]` |
| `rover_navigate` | **span** over the whole batched plan |
| everything else | instantaneous frame |

## Image dereferencing
Inline image blocks (base64) MUST be replaced by references into the LeRobot
video, e.g.:
```
observation.images.front#frame=8
```
The frame these reference is computed by the binding rules above. This avoids
duplicating bytes already present in the mp4 and preserves the video↔reasoning
join.

## Write-time vs export-time
- If an episode is recording at emit time → `frame_index` filled immediately.
- If ambient (no episode) → `frame_index = NULL`; the exporter reconciles later
  against `episode_anchors` (nearest / overlapping episode), or keeps it in a
  separate ambient track.
