# Issue types

Each issue has one type. The type sets a label and a title prefix. Wayfinder child issues are the exception. See [Wayfinder](#wayfinder).

| Type    | Label          | Title prefix | Use                                                                                                      |
| ------- | -------------- | ------------ | -------------------------------------------------------------------------------------------------------- |
| Epic    | `type:epic`    | `[Epic]`     | A large piece of work and its discussion. Example: `[Epic] Plugin system`.                               |
| Bug     | `type:bug`     | `[Bug]`      | A failure that the automated tests do not catch: a person or a manual check sees it.                     |
| Feature | `type:feature` | `[Feature]`  | A spec that adds new behavior.                                                                           |
| Task    | `type:task`    | `[Task]`     | A spec that changes existing behavior: a fix, a refactor, or a behavior correction.                      |
| Ticket  | `type:ticket`  | `[Ticket]`   | One unit of work for an implementation agent, cut from a Feature or a Task. One ticket is one review stop. |

## Hierarchy

```
Epic ──► Feature / Task ──► Ticket
Bug  ──► Feature / Task ──► Ticket
```

- Link each level with native GitHub sub-issues. Link siblings with native `blocked_by`. See `issue-tracker.md` for the commands and the fallback.
- Every Feature and every Task gets 1 or more Tickets. Implementation work starts only from a Ticket.
- The change sets the type, not the parent. New behavior is a Feature, also under a Bug. A change to existing behavior is a Task, also under an Epic.
- Apply `ready-for-agent` to Features, Tasks, and Tickets.

## Wayfinder

- To run `/wayfinder` on an Epic, add `wayfinder:map` to the same issue. The Epic keeps `type:epic` and `[Epic]`.
- A Bug with an unclear cause can also become a map in the same way. It keeps `type:bug` and `[Bug]`. A Bug with a clear cause goes directly to Features or Tasks.
- Wayfinder child issues get only their `wayfinder:<type>` label, with no `type:*` label. Prefix their titles with `[WF]`.

## Not a Bug

If a test or the project check fails during a ticket, fix the failure in the current ticket. Do not open an issue.
