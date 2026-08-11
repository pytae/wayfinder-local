---
name: wayfinder-local
description: Create and resume large multi-session efforts as local decision-ticket maps. The exact first argument `create` initializes a project; every other invocation resolves and continues an existing map by stable slug.
---

A loose idea has arrived — too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **shared map** on the repo's issue tracker, then works its **decision tickets** — questions whose resolution is a decision, not slices of a build to execute — one at a time until the route is clear.

The destination varies per effort, and naming it is the first act of charting — it shapes every ticket. It might be a spec to hand off and iterate on, a decision to lock before planning starts, or a change made in place like a data-structure migration. The map is domain-agnostic — engineering work, course content, whatever fits the shape.

## Plan, don't do

Wayfinder is **planning** by default: each ticket resolves a decision, and the map is done when the way is clear — nothing left to decide before someone goes and does the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off. An effort can override this in its **Notes** — carrying execution into the map itself — but absent that, produce decisions, not deliverables.

## Refer by name

Every map and ticket is an issue, so it has a **name** — its title. In everything the human reads — narration, the map's Decisions-so-far — refer to it by that name, never by a bare id, number, or slug. A wall of `#42, #43, #44` is illegible; names read at a glance. The id and URL don't vanish — a name wraps its link — but they ride _inside_ the name, never stand in for it.

## The Map

The map is a single issue on this repo's issue tracker, labelled `wayfinder:map` — the canonical artifact. Its tickets are child issues of the map.

The map is an **index**, not a store. It lists the decisions made and points at the tickets that hold their detail; a decision lives in exactly one place — its ticket — so the map never restates it, only gists it and links.

**Where the map, its child tickets, blocking, and frontier queries physically live is tracker-specific.** The issue tracker should have been provided to you — run `/setup-matt-pocock-skills` if not. Consult the tracker doc's "Wayfinding operations" section for how _this_ repo expresses them. If no tracker has been provided, default to the local-markdown tracker.

### The map body

The whole map at low resolution, loaded once per session. Open tickets are **not** listed — they are open child issues, found by query.

```markdown
---
slug: <stable-lowercase-name>
tracker: <tracker type from the repository's Wayfinding operations>
---

## Destination

<what reaching the end of this map looks like — the spec, decision, or change this effort is finding its way to. One or two lines; every session orients to it before choosing a ticket.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index — one line per closed ticket: enough to judge relevance, then zoom the link for the detail the ticket holds -->

- [<closed ticket title>](link) — <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog you can't ticket yet; graduates as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is a **child issue** of the map; the tracker's issue id is its identity. Its body is the question, sized to one 100K token agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket carries a `wayfinder:<type>` label — one of `research`, `prototype`, `grilling`, `task` (see [Ticket Types](#ticket-types)).

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work, so concurrent sessions skip it. That assignee _is_ the claim: an open, unassigned ticket is unclaimed.

Blocking uses the tracker's **native** dependency relationship — essential because it renders the frontier _visually_ in the tracker's own UI, so the human sees what's takeable without opening the map. Only a tracker that lacks native blocking falls back to a body convention. A ticket is **unblocked** when every ticket blocking it is closed; the **frontier** is the open, unblocked, unclaimed children — the edge of the known.

The answer isn't part of the body — it's recorded on resolution (see [Work through the map](#work-through-the-map)). Assets created while resolving a ticket are linked from the issue, not pasted in.

## Ticket Types

Every ticket is either **HITL** — human in the loop, worked _with_ a human who speaks for themselves — or **AFK**, driven by the agent alone. A HITL ticket only resolves through that live exchange; the agent never stands in for the human's side of it (a grilling agent that answers its own questions has broken this).

- **Research** (AFK): Reading documentation, third-party APIs, or local resources like knowledge bases to surface a fact a decision waits on. Resolved by a `/research` **subagent**. Use when knowledge outside the current working directory is required.
- **Prototype** (HITL): Raise the fidelity of the discussion by making a cheap, rough, concrete artifact to react to — an outline, a rough take, a stub, or UI/logic code via the /prototype skill. Links the prototype as an asset. Use when "how should it look" or "how should it behave" is the key question.
- **Grilling** (HITL): Conversation. The default case. Always invoke the /grilling and /domain-modeling skills.
- **Task** (HITL or AFK): Manual work that must happen before a _decision_ can be made — nothing to decide, prototype, or research, but the discussion is blocked until it's done. Signing up for a service so its API can be judged, provisioning access, moving data so its shape can be seen. This is the one type that _does_ rather than decides — and it earns its place by unblocking a decision, not by delivering the destination. The agent drives it alone where it can (AFK); otherwise it hands the human a precise checklist (HITL). Resolved when the work is done; the answer records what was done and any resulting facts (credentials location, new URLs, row counts) later tickets depend on.

## Fog of war

The map is _deliberately_ incomplete: don't chart what you can't yet see. Beyond the live tickets lies the **fog of war** — the dim view of decisions and investigations you can tell are coming but can't yet pin down, because they hang on questions still open. Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets — one at a time, until the way to the destination is clear and no tickets remain.

The map's **Not yet specified** section is where that dim view is written down: the suspected question, the area to revisit later. It's the undiscovered frontier _toward_ the destination — everything here is in scope, just not sharp enough to ticket. Write as loosely or as fully as the view allows; it doubles as a signpost for collaborators reading where the effort is headed.

**Fog or ticket?** The test is whether you can state the question precisely now — _not_ whether you can answer it now.

- **Ticket when** the question is already sharp — even if it's blocked and you can't act on it yet.
- **Not yet specified when** you can't yet phrase it that sharply. Don't pre-slice the fog into ticket-sized pieces: it's coarser than a ticket, and one patch may graduate into several tickets, or none, once the frontier reaches it.

**Not yet specified** excludes what's already decided (Decisions so far), what's already a live ticket, and what's out of scope (the next section).

## Out of scope

Fog only ever gathers _toward_ the destination. The destination fixes the scope, so work beyond it is **out of scope** — it isn't fog, and it doesn't belong in **Not yet specified**. It gets its own **Out of scope** section on the map: work you've consciously ruled out of _this_ effort. Scope, not sharpness, lands it here.

Out-of-scope work never graduates — the frontier stops at the destination — so it returns only if the destination is redrawn, and then as a fresh effort, not a resumption.

Ruling something out of scope is a scoping act, not a step on the route. When a ticket that already exists turns out to sit past the destination — mis-scoped in while charting, or exposed by a resolution — **close it** (a closed ticket is unambiguously off the frontier) and leave one line in the **Out of scope** section: the gist plus why it's out of scope, linking the closed ticket. It stays out of **Decisions so far**, which records the route actually walked — a scope boundary isn't a step on it.

## Choose create or continue

Parse the first positional token immediately after `/wayfinder-local` (or `$wayfinder-local`):

- Exact token `create`: select **create** and remove that token before interpreting the remaining input.
- Every other token: select **continue** and preserve the entire remaining prompt as work within an existing map.

Creation is a command boundary, not an inferred intent. A later use of the word `create` remains continue-mode task content. For example, `/wayfinder-local noctas-docs-review create an implementation outline` continues `noctas-docs-review`; it does not initialize another map. If continue mode has no resolvable map reference, ask for one instead of falling through to create mode.

In create mode:

- Treat one slug-shaped token as an explicit slug: `/wayfinder-local create noctas-docs-review`.
- Otherwise treat the remaining text as the initial idea and derive the slug from it: `/wayfinder-local create Review and restructure the Noctas documentation`.
- When the user clearly supplies both, preserve the explicit slug and the idea.
- When neither a slug nor an idea remains, ask for the idea.

Run the bundled creator from the project root. Omit `-Slug` when it should be derived from the idea:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <wayfinder-skill>/scripts/create-map.ps1 -Intent create -Slug '<slug>' -Idea '<idea>' -WorkspaceRoot (Get-Location).Path
```

The creator requires the exact `-Intent create` guard, writes `data/wayfinder/<slug>/map.md` with `tracker: local-markdown`, a provisional destination, and the initial idea, and never overwrites an existing map. For `created`, run the resolver on the returned slug and continue to **Chart the map**. For `already-exists`, report the canonical path and ask whether to continue that map or choose another slug. For `invalid`, report the reason and correct the input.

In continue mode, treat the invocation argument as a map reference. Run the bundled resolver from the project root before loading tracker tools:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <wayfinder-skill>/scripts/resolve-map.ps1 -Reference '<argument>' -WorkspaceRoot (Get-Location).Path
```

For a bare slug, the resolver directly checks `.wayfinder/maps.json`, `data/wayfinder/<slug>/map.md`, and `.wayfinder/<slug>/map.md`. It does not depend on Git, file discovery, ignore rules, SQLite, or GitHub search. A project alias file has this shape:

```json
{
  "maps": {
    "project-slug": "relative/path/to/map.md"
  }
}
```

Then:

1. For `resolved`, load only `canonicalPath` and read its `tracker` field before loading tracker-specific tools.
2. For `direct` or `tracker-reference`, load the URL or issue through the repository's Wayfinding operations and establish its tracker.
3. For `unresolved`, `ambiguous`, or `invalid-map`, report the resolver's reason and every checked location, then ask the user for the canonical map. Do not infer a tracker.

An existing local map wins over tracker inference. A slug-resolved map must contain matching `slug` and non-empty `tracker` frontmatter. Completion criterion: exactly one canonical map is loaded and its tracker is established.

## Invocation

After create-or-continue routing, either chart a new map or work through an existing one. **Never resolve more than one ticket per session** — with the exception of research tickets.

### Chart the map

User enters create mode with a slug, an idea, or both.

1. **Load the initialized map.** Confirm the creator and resolver agree on its canonical path, slug, and tracker.
2. **Name the destination.** Run a `/grilling` and `/domain-modeling` session to pin down what this map is finding its way to — the spec, decision, or change — then replace the provisional Destination. The destination fixes the scope, so settle it first.
3. **Map the frontier.** Grill again, **breadth-first** this time: fan out across the whole space rather than deep on any one thread, surfacing the open decisions and the first steps takeable now. If this surfaces no fog, record the completed destination and stop without creating tickets.
4. **Update the map** (label `wayfinder:map`): preserve its slug and tracker, fill Destination and Notes, leave Decisions-so-far empty, and sketch the fog into **Not yet specified**.
5. **Create the tickets you can specify now** as child issues of the map — then wire blocking edges in a **second pass** (issues need ids before they can reference each other). Wiring sorts them into the frontier and the blocked; everything you can't yet specify stays in the fog — the **Not yet specified** section.
6. **Fire the research subagents.** For each `research` ticket you just created, spin up a `/research` subagent to resolve it in parallel, capturing its findings on a throwaway `research/<name>` branch with a context pointer from the ticket.
7. Stop — charting is one session's work; it hand-resolves nothing.

### Work through the map

User invokes with a map reference (slug, path, URL, or issue number). A ticket is **optional** — without one, you pick the next decision, not the user.

1. Resolve and load the **map** — the low-res view, not every ticket body.
2. Choose the ticket. If the user named one, use it. Otherwise take the first frontier ticket in order. **Claim it**: assign it to yourself before any work.
3. Resolve it — **zoom as needed**: fetch the full body of any related or closed ticket on demand; invoke the skills the `## Notes` block names. If in doubt, use `/grilling` and `/domain-modeling`.
4. Record the resolution: post the answer as a **resolution comment**, **close** the issue, and **append a context pointer** to the map's Decisions-so-far.
5. Add newly-surfaced tickets (create-then-wire); graduate any fog the answer has made specifiable, clearing each graduated patch from **Not yet specified** so it lives only as its new ticket. If the answer reveals a ticket — this one or another — sits beyond the destination, **rule it out of scope** rather than resolving it on the route. If the decision invalidates other parts of the map, update or delete those tickets.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the tracker concurrently.
