# Wayfinder Local

Wayfinder Local is a local-first adaptation of Matthew Pocock's Wayfinder agent skill. It helps an agent navigate an effort too large or uncertain for one session by maintaining a shared map of decision tickets and resolving one decision at a time.

This version adds deterministic map resumption with a stable slug:

```text
/wayfinder my-big-project
```

The agent resolves that slug directly to one canonical map, reads the map's declared tracker, and continues from the tracker's live state. It does not need a prose handoff document or a context-heavy prompt from the previous session.

## What this fork changes

- Adds required `slug` and `tracker` metadata to every map.
- Defines `data/wayfinder/<slug>/map.md` as the preferred local Markdown location.
- Bundles a deterministic PowerShell resolver.
- Supports project-level aliases in `.wayfinder/maps.json`.
- Checks local paths directly, including files hidden by `.gitignore`.
- Reports missing, invalid, or ambiguous maps instead of guessing a tracker.
- Avoids SQLite and GitHub search during slug resolution.
- Preserves Wayfinder's one-ticket-per-session planning workflow.
- Does not prescribe a handoff document or special end-of-session prompt.

The resolver finds the map; it does not implement the issue tracker. Each project still defines its tracker-specific Wayfinding operations for maps, tickets, claims, dependencies, and frontier queries.

## Repository contents

```text
wayfinder-local/
|-- SKILL.md
|-- agents/
|   `-- openai.yaml
`-- scripts/
    `-- resolve-map.ps1
```

- `SKILL.md` contains the Wayfinder workflow and resolution contract.
- `agents/openai.yaml` provides Codex-facing display metadata.
- `scripts/resolve-map.ps1` resolves a slug, path, URL, or issue number.

## Installation

Clone the repository into the skill directory used by your agent host. Keep the installed folder named `wayfinder` when the host derives `/wayfinder` from the directory name.

Example for a Windows agent-skills directory:

```powershell
git clone https://github.com/wearyscary/wayfinder-local.git "$HOME\.agents\skills\wayfinder"
```

If you already have a `wayfinder` skill installed, preserve any changes you want to keep and replace it with this version.

## Quick start

### 1. Create a canonical map

From the project root, create:

```text
data/wayfinder/my-big-project/map.md
```

Start it with matching metadata:

```markdown
---
slug: my-big-project
tracker: local-markdown
---

## Destination

Describe what reaching the end of this map means.

## Notes

Record standing preferences, domain context, and skills each session should consult.

## Decisions so far

## Not yet specified

## Out of scope
```

Use the tracker identifier defined by the project's Wayfinding operations. `local-markdown` is appropriate only when the project uses that tracker.

### 2. Resume by slug

Open a session at the project root and invoke:

```text
/wayfinder my-big-project
```

The resolver returns the canonical map path and tracker before the agent loads tracker-specific tools or chooses a ticket.

## Map aliases

Use an alias when an existing map cannot live at a canonical location. Create `.wayfinder/maps.json` in the project root:

```json
{
  "maps": {
    "my-big-project": "planning/current-map.md"
  }
}
```

The referenced map must still declare the same slug:

```yaml
---
slug: my-big-project
tracker: local-markdown
---
```

Relative alias paths are resolved from the project root.

## Resolution behavior

For a bare slug, the resolver checks:

1. `.wayfinder/maps.json`
2. `data/wayfinder/<slug>/map.md`
3. `.wayfinder/<slug>/map.md`

Candidates that resolve to the same absolute file are deduplicated. Distinct matching files produce an ambiguity error rather than an arbitrary choice.

The resolver also accepts:

- An HTTP or HTTPS map URL.
- An issue number for the project's configured tracker.
- An absolute or project-relative filesystem path.
- A directory path containing `map.md`.

Slug resolution requires lowercase letters, digits, and hyphens, with a maximum length of 64 characters.

## Run the resolver directly

The skill normally runs the resolver for the agent. To inspect resolution yourself:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "<wayfinder-skill>\scripts\resolve-map.ps1" `
  -Reference "my-big-project" `
  -WorkspaceRoot "C:\path\to\project"
```

The command emits JSON. Important statuses include:

- `resolved`: exactly one local map was found.
- `direct`: the reference is a URL.
- `tracker-reference`: the reference is an issue number.
- `unresolved`: no valid map was found.
- `ambiguous`: more than one distinct map matched.
- `invalid-map`: required metadata is missing or inconsistent.

Failure output includes the locations checked, allowing the project configuration to be corrected without falling back to tracker inference.

## Wayfinder workflow

Wayfinder remains a planning workflow:

1. Define the destination.
2. Chart only the visible frontier of decisions.
3. Keep uncertain future questions in the map's fog of war.
4. Claim one unblocked, unassigned decision ticket.
5. Resolve that decision and record it in the tracker.
6. Update the frontier as new questions become visible.

By default, a session resolves no more than one ticket. Research tickets are the documented exception and may be delegated in parallel.

## Attribution

Based on the Wayfinder skill from [Matthew Pocock's skills repository](https://github.com/mattpocock/skills/tree/main/skills/engineering/wayfinder). This repository carries local slug resolution and handoff changes specific to this adaptation.
