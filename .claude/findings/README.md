# Session findings

Findings recorded by the session review hook. See the Tooling section of [the roadmap](../../docs/ROADMAP.md).

## Rules
- **One finding per JSON file.** Writers never edit another writer's file, so parallel sessions cannot clobber each other.
- **Never delete a finding.** Outcomes are recorded with `status` and `statusReason`. A finding that is not acted on gets `status: "dismissed"` with a reason.
- **History is append only.** Every status change updates `status`, `statusReason`, `statusUpdatedAt` and `issue`, and appends the same values to `history`.
- **Findings are committed.** They land on `main` through a one-commit triage PR, like any other change. CI rejects a PR that deletes a finding file or adds one that fails the schema.
- **Excerpts stay safe to commit.** Evidence quotes must not contain secrets, tokens, credentials, or personal data. Paraphrase instead.

## File names
```
<UTC timestamp>-<first 8 chars of session id>-<2-digit sequence>.json
20261016T142233Z-3f9a1c2e-01.json
```
The `id` field equals the file name without `.json`. Names sort by creation time.

Writers create files with a temporary name and rename them into place. They refuse to overwrite an existing file.

Every `.json` file in this folder except `finding.schema.json` is a finding.

## From session to `main`
1. The session review hook writes new findings as untracked files in the main checkout's copy of this folder, whichever worktree the session ran in.
2. `/triage-findings` sets each open finding's status with the operator.
3. It then moves the new and changed files into a `findings/<date>` worktree branch as one commit and ships the PR. Moving the untracked copies out of the main checkout keeps them from blocking the next `git pull`.
4. A finding can be committed while still `open`. A later triage PR updates its status.

## Status
| Status | Meaning | `issue` |
|---|---|---|
| `open` | Awaiting triage. `statusReason` is null. | null |
| `filed` | Became a new GitHub issue. | The new issue |
| `folded` | Added to an existing issue as a comment or body change. | The existing issue |
| `dismissed` | Not acted on. `statusReason` says why. | null |

## Schema
[`finding.schema.json`](finding.schema.json) is the source of truth. Bump `schemaVersion` on breaking changes.

## Example
```json
{
  "schemaVersion": 1,
  "id": "20261016T142233Z-3f9a1c2e-01",
  "createdAt": "2026-10-16T14:22:33Z",
  "session": {
    "id": "3f9a1c2e-7b1d-4c55-9e0a-2d8f1b6a4c10",
    "endReason": "prompt_input_exit",
    "branch": "eharvey/#12",
    "worktree": "/Users/eharvey/shared-pets-wt/12",
    "transcriptPath": null
  },
  "category": "doc-drift",
  "title": "Update ARCHITECTURE.md to match the M0.5 sync spike outcome",
  "summary": "The spike dropped SwiftData for the shared zone, but the architecture doc still lists SwiftData as the local store.",
  "evidence": [
    { "kind": "file", "path": "docs/ARCHITECTURE.md", "line": 11 }
  ],
  "recommendation": "file",
  "relatedIssues": [],
  "status": "dismissed",
  "statusReason": "Already covered by the spike's exit criteria in #9.",
  "statusUpdatedAt": "2026-10-17T09:05:00Z",
  "issue": null,
  "history": [
    { "status": "open", "statusReason": null, "at": "2026-10-16T14:22:33Z", "issue": null },
    { "status": "dismissed", "statusReason": "Already covered by the spike's exit criteria in #9.", "at": "2026-10-17T09:05:00Z", "issue": null }
  ]
}
```
