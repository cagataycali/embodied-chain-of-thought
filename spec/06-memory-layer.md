# ECoT Spec §6 — Memory Layer (multimodal time-keyed recall)

OPTIONAL but recommended. A recall layer that sits **on top of** the dataset
spine — it does NOT duplicate pixels. Every memory row carries the same time
bridge (`wall_ts` + `dataset/episode/frame_index`) so a search hit points back
into the real video (the replay scrubber can seek to it) and into the parquet
(the action/state at that instant).

> Contrast with QR-in-video schemes (e.g. memvid): those encode text into fake
> video frames because they lack a real store. ECoT already has the real frames
> + parquet + reasoning DB, so memory is an **index keyed on `frame_index`**,
> not a duplicate corpus. Recall *is* dataset navigation.

## Modalities (one vector table, unified on time)

| modality | encoder | source | enables |
|---|---|---|---|
| `image`  | CLIP (shared image+text space) | keyframes | text→image recall ("when did I see X") |
| `text`   | CLIP text tower | reasoning events + turns | semantic reasoning recall |
| `object` | object detector (e.g. YOLO) → labels, text-embedded | keyframes | structured object filter |
| `audio`  | ASR (e.g. Whisper) | audio sidecars | spoken context search |

Image and text MUST share one embedding space (e.g. CLIP) so cross-modal query
works. Cosine metric. On-disk vector table (offline, portable).

## Table schema (reference)

```
vector        : float32[D]    # shared-space embedding (image or text)
id            : str           # repo:episode:frame:modality:source:ts_ms
modality      : str           # image | text | object | audio
source        : str           # frame | reasoning:<type> | <detector> | <asr> | turn
dataset       : str
episode       : int           # MUST be LeRobot-aligned (see §2 off-by-one note)
frame_index   : int           # JOIN KEY → video seek / parquet lookup
wall_ts       : float
t_in_episode  : float
text          : str
objects       : str           # comma-joined labels (filterable)
meta          : str           # JSON
```

## Search semantics

- Query MAY be text or image (both → shared space).
- Implementations SHOULD use **per-modality top-k then merge**, because
  text↔text cosine sits systematically above text↔image (the CLIP "modality
  gap") — a single pool buries visual hits under textual ones.
- Filters (`modality`, `episode`, `time_range`, `objects`) compose with the
  vector search.
- Each hit MUST expose `frame_index` (and SHOULD expose `t_in_episode`) so the
  consumer can seek the video and pull the aligned action chunk.

## Recall flow

```
query ──embed──▶ vector search (per-modality top-k)
      ──▶ hit{episode, frame_index, t_in_episode}
      ──▶ video seek: video_from + t_in_episode
      ──▶ frame_index ──▶ parquet action/state at that instant
```

## Cost & placement (SHOULD)

- Enrichment SHOULD run **offline** (after `stop_episode`, or scheduled) so the
  encoders never compete with the dense recorder for CPU/IO.
- Keyframe sub-sampling SHOULD be used (e.g. ~1 FPS + motion transitions)
  rather than embedding every frame.
- Re-enrichment SHOULD be idempotent (delete-by-episode then re-add).

## Conformance (memory layer)

- [ ] Vector rows carry `frame_index` (+ `wall_ts`) → seekable back into the dataset.
- [ ] Image + text share one embedding space (cross-modal query works).
- [ ] Search supports per-modality top-k merge (modality-gap mitigation).
- [ ] `episode` is LeRobot-aligned (no off-by-one vs `meta`).
- [ ] Enrichment is offline + idempotent.
