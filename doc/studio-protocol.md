# WebSocket Protocol

[Back to index](index.md)

The Studio GUI communicates with LOVJ via JSON messages over WebSocket (port 8765). Messages have a `type` field and an optional `id` for request/response correlation.

## Connection Flow

1. Client opens WebSocket to `ws://hostname:8765`
2. Client sends `{type: "hello", id: N}`
3. Server responds with `{type: "welcome", id: N, version, slots, selectedSlot}`
4. Client fetches initial state via parallel requests

## Request/Response

Messages with an `id` field expect a correlated response. Messages without `id` are fire-and-forget commands or broadcasts.

## Client → Server Messages

### Discovery

| Type | Fields | Response |
|------|--------|----------|
| `hello` | — | `welcome` |
| `listSlots` | — | `slots` |
| `getSchema` | `slot` | `schema` |
| `listAvailablePatches` | — | `availablePatches` |

### Parameters

| Type | Fields | Response |
|------|--------|----------|
| `setParam` | `slot`, `name`, `value` | — (broadcasts `paramChanged`) |

### Modulators

| Type | Fields | Response |
|------|--------|----------|
| `listModulators` | — | `modulatorList` |
| `createModulator` | `config` | broadcasts `modulatorList` |
| `updateModulator` | `id`, `changes` | broadcasts `modulatorList` |
| `deleteModulator` | `id` | broadcasts `modulatorList` |

### Sequencer

| Type | Fields | Response |
|------|--------|----------|
| `getSequencer` | — | `sequencerState` |
| `sequencerPlay` | — | broadcasts `sequencerState` |
| `sequencerStop` | — | broadcasts `sequencerState` |
| `sequencerAddChannel` | `name`, `target`, `steps`, `divider` | broadcasts `sequencerState` |
| `sequencerRemoveChannel` | `name` | broadcasts `sequencerState` |
| `sequencerUpdateChannel` | `name`, `steps?`, `divider?` | broadcasts `sequencerState` |
| `sequencerPlock` | `step`, `channel`, `value` | broadcasts `sequencerState` |

### Scene Sequencer

| Type | Fields | Response |
|------|--------|----------|
| `getSceneSequencer` | — | `sceneSequencerState` |
| `sceneSeqPlay` | — | broadcasts `sceneSequencerState` |
| `sceneSeqStop` | — | broadcasts `sceneSequencerState` |
| `sceneSeqCacheScene` | `label`, `sceneType`, `patchPath?`, `slot?` | broadcasts `sceneSequencerState` |
| `sceneSeqAddChannel` | `name`, `slot`, `steps`, `divider` | broadcasts `sceneSequencerState` |
| `sceneSeqRemoveChannel` | `name` | broadcasts `sceneSequencerState` |
| `sceneSeqUpdateChannel` | `name`, `steps?`, `divider?` | broadcasts `sceneSequencerState` |
| `sceneSeqSetScene` | `step`, `channel`, `label` | broadcasts `sceneSequencerState` |

### Patch Management

| Type | Fields | Response |
|------|--------|----------|
| `loadPatch` | `slot`, `patchName` | `patchLoaded` |

### Shaders

| Type | Fields | Response |
|------|--------|----------|
| `getSlotShaders` | `slot` | `slotShaders` |
| `setSlotShader` | `slot`, `layer`, `shaderIndex` | — |
| `setShaderParam` | `slot`, `name`, `value` | — |
| `toggleShaders` | `enable` | `shadersToggled` |

### Savestates

| Type | Fields | Response |
|------|--------|----------|
| `listSavestates` | `slot` | `savestateList` |
| `saveSavestate` | `slot`, `savestateId` | `savestateSaved` |
| `loadSavestate` | `slot`, `savestateId` | `savestateLoaded` |

### Transport

| Type | Fields | Response |
|------|--------|----------|
| `setBPM` | `bpm` | broadcasts `bpmChanged` |
| `resetPhase` | — | — |

## Server → Client Broadcasts

These are sent to all connected clients without a request `id`:

| Type | Fields | Trigger |
|------|--------|---------|
| `paramChanged` | `slot`, `name`, `value` | Any parameter change (throttled to 30 Hz) |
| `modulatorList` | `modulators`, `shapes` | Modulator created/updated/deleted |
| `sequencerState` | full state | Sequencer changed |
| `sceneSequencerState` | full state | Scene sequencer changed |
| `bpmChanged` | `bpm` | BPM changed |
| `patchLoaded` | `slot`, `patchName` | Patch loaded in any slot |
| `savestateLoaded` | `slot`, `savestateId` | Savestate loaded |
| `savestateSaved` | `slot`, `savestateId` | Savestate saved |

## Error Handling

Errors are returned as `{type: "error", id?, message}`. The client's transport layer rejects the pending promise for that `id`.

## Related

- [Studio Overview](studio.md) — GUI architecture and tabs
- [Command System](commands.md) — commands available through the protocol
