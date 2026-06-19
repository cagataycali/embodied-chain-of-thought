# ECoT Spec §4 — The ChatML / ECoT View

The exporter materializes events into an interleaved, frame-aligned, multi-turn
training sample.

## Extended `_strands_to_openai` (frame-ref aware)
Differs from a vanilla Strands→OpenAI converter:
- image blocks become frame **references** (no base64);
- each message carries `_meta {agent_id, frame_index, t, frame_span?}`;
- `tool_use_id` ↔ `tool_call_id` correlation preserved;
- consecutive assistant `tool_use` blocks merge into one assistant message with
  a `tool_calls` array (native `<tool_call>` token emission);
- `assistant_end` closes the assistant message.

## Sample shape
```jsonc
{
  "episode_index": 7,
  "repo_id": "scout/earth-rover-mini-...",
  "fps": 4,
  "system": "<full system prompt>",
  "tools": [ {"name":"rover_move","description":"...","input_schema":{...}}, ... ],
  "messages": [
    {"role":"user","content":"go to the doorway",
     "_meta":{"agent_id":"telegram","frame_index":0,"t":0.0}},
    {"role":"assistant","content":"Doorway ahead-left; I'll look first.",
     "tool_calls":[{"id":"tu_1","type":"function",
        "function":{"name":"rover_see","arguments":"{\"camera\":\"front\"}"}}],
     "_meta":{"agent_id":"main","frame_index":1,"t":0.3}},
    {"role":"tool","tool_call_id":"tu_1",
     "content":"observation.images.front#frame=1","_meta":{"frame_index":1}},
    {"role":"assistant","content":"Clear path. Driving forward.",
     "tool_calls":[{"id":"tu_2","type":"function",
        "function":{"name":"rover_move","arguments":"{\"linear\":0.3,\"duration\":2}"}}],
     "_meta":{"frame_index":2,"frame_span":[2,10],"t":0.6}},
    {"role":"tool","tool_call_id":"tu_2",
     "content":"Moved. observation.images.front#frame=10",
     "_meta":{"frame_index":10,"frame_span":[2,10]}}
  ],
  "action_chunks": [
    {"tool_use_id":"tu_2","frames":[2,10],
     "actions":[[0.3,0.1,0],[0.3,0.1,0], ...]}
  ]
}
```

## `action_chunks` — the VLA bridge
For each motion `tool_use` with a `frame_span`, pull the matching `action` rows
from the LeRobot parquet → the H-step action targets. This binds language
reasoning to the **actual continuous control** the VLA learns. This is the ECoT
join, realized.
