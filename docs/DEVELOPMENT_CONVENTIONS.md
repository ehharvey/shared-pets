# Development Conventions

How we work: branching, commits, PRs, review state, and tooling. Not architecture; see [ARCHITECTURE.md](ARCHITECTURE.md) and [ROADMAP.md](ROADMAP.md) for that. Adapted from [ehharvey/homelab-ops](https://github.com/ehharvey/homelab-ops)'s `docs/Development Conventions.md`; references like `homelab-ops#119` in scripts point at the issue there that motivated a rule.

## Supersede in place

A decision or an issue body always reads as the **current** rule. Changes don't stack: every reader, human or Claude, would otherwise have to reconcile the layers, and pay in tokens to read the dead ones.

**When a decision changes:**

- **Rewrite the rule in place.** Edit the body so it states what holds now. Don't append an addendum that overrides it.
- **Fold findings in where they apply.** What building something settled goes into the part of the body it refines.
- **Mark what was replaced as superseded, with a link.** A short pointer where the old rule stood is enough.
- **Keep the history in a closing `### History` subsection.** One dated entry per change, with its issue or PR: what changed and, for a reversal, why.
- **Cite the section, not the addendum** (`§2`, not "§2's #14 addendum"), so citations survive the next change.

**When an issue's scope changes:** edit the body so it states the current spec, and post the change as a comment: a dated note saying what changed and why. The body is what an implementer reads; the comments are the history.

## Branching & issues

- One branch per issue, named `eharvey/#<issue-number>`. `make wt N=<n>` makes it in its own worktree.
- Work lands via PR, never by pushing to `main`. The ruleset refuses direct pushes, force-pushes and deletion of `main`.
- The commit message includes `Closes #<n>`, so merging auto-closes the issue. Don't close issues manually.
- **One issue, one commit.** `main` merges PRs with rebase only, never squash or merge commits, so a branch with N commits lands as N commits. The branch itself has to be the single commit.
- **One identity: GitHub's noreply address.** Every human commit's author and committer is `Emil Harvey <36806437+ehharvey@users.noreply.github.com>`; a bot's is its own `<id>+<name>[bot]@users.noreply.github.com`. `make hooks` sets it as the repo-local identity, which covers every worktree. `.githooks/pre-push` refuses a push with any other address, the required `one-commit` job checks the PR's commit, and `ci.yml`'s `landed-identity` job checks what landed on `main` (all `scripts/check-commit-identity.sh`). The repo is public, so a personal address in a commit is published for good ([DECISIONS.md §2](DECISIONS.md)).

Landing finished work is two steps (`scripts/ship.sh`, `scripts/lgtm.sh`):

- **`make ship`** pushes and opens the PR with `gh pr create --fill`, then stops. First it makes the branch shippable: several commits are squashed into one that keeps the *first* commit's message, and a branch behind `main` is rebased onto it, never merged. It refuses, pushing nothing, when a rebase is in progress, when its own rebase stops on a conflict, or when the branch is stacked on another branch. Then it copies the issue's title and details into the commit (§ PR body format), and refuses a message lacking `## Plan`, `## Test plan` or `Closes #<n>` (`scripts/check-commit-msg.sh`, which the `one-commit` CI job also runs). Run it again after amending to re-ship to the open PR: it force-pushes with a lease on the PR's head SHA.
- **`make lgtm`** enables auto-merge on the branch's PR, so it merges once the required checks pass. `make lgtm PR=<n>` for a PR opened another way. **That's the operator's call, never Claude's unless asked.**

Splitting them keeps a PR from merging before anyone has read it. It's a speed bump, not an enforced control: GitHub won't let you approve your own PR, so `required_approving_review_count` is 0 and `make lgtm` is the honour-system stand-in. It runs locally rather than as a workflow reacting to a comment, because a merge enabled with `GITHUB_TOKEN` is attributed to `github-actions[bot]` and its pushes start no further workflow runs.

Three things enforce the one-commit shape, fastest first:

1. `.githooks/pre-push` refuses a multi-commit push locally (install once with `make hooks`, which also sets `commit.cleanup=scissors`). Claude Code's worktree setup rewrites `core.hooksPath` to the main checkout's absolute `.githooks`, so every hook first sources `.githooks/run-own-copy.sh`, which hands off to the pushing worktree's own copy.
2. The `one-commit` job in `.github/workflows/pr-shape.yml` fails the PR. Its later steps also fail it when the commit's identity isn't the noreply address or its message lacks the sections or a `Closes` line.
3. `one-commit` is a required status check on `main`.

`make ship` squashes for you; the hook and the check refuse and print the manual form:

```sh
git fetch origin main
git reset --soft "$(git merge-base FETCH_HEAD HEAD)"
git commit -C "$(git rev-list --reverse FETCH_HEAD..HEAD@{1} | head -1)"
```

It resets to the merge-base, not `FETCH_HEAD`, because on a branch behind `main` a soft reset to `FETCH_HEAD` silently reverts what landed since. It reuses the *first* commit's message, where the Plan and Test plan were written, verbatim with `-C`: `-c` opens an editor whose default cleanup deletes every `#` line, `## Plan` included.

### Sizing and bundles

Every issue pays a roughly fixed pipeline cost (scout, implement, lint, review, ship), so a 10-line fix costs about what a 100-line one does.

- **`small`** means the change is expected to be **≤ ~100 lines in one area**, with **no open design question**. It's a sizing hint, not a priority.
- **A bundle** is a `[Task]: Bundle: …` parent issue with its `small` issues attached as native sub-issues. It ships as one branch, `eharvey/#<parent>`, and one commit whose message has `Closes #<parent>` plus one `Closes #<n>` per open sub-issue (`make ship`'s block adds those; `.claude/skills/lib.jq` defines a bundle). An umbrella issue (any other title, like #11) doesn't bundle: its sub-issues still ship alone.

## Review state labels

Labels show, from the PR list, whether a PR has had the reviews it needs before `make lgtm`. `scripts/review-state.sh` is the one implementation; `make ship` and `.github/workflows/review-state.yml` run it.

| Label | On while |
|---|---|
| `reviewed-work` | a `/review-work` verdict is posted on the PR |
| `review-unaddressed` | any posted `/code-review` pass or `/review-work` verdict isn't addressed yet |
| `review-passes-left-<n>` | `n` more `/code-review` passes are expected; stays on at `0` |

- **The merge gate.** A PR is ready for `make lgtm` when it has `reviewed-work` and `review-passes-left-0`, and doesn't have `review-unaddressed` (`scripts/review-gate.jq`). It informs `make lgtm` and enforces nothing.
- **A pass** is one `/code-review` review posted on the PR that opened a thread. Empty-body reviews that open threads back to back on one commit, each within 60s of the one before, are one pass. A **clean pass** is a `scripts/review-state.sh <pr> --clean-pass --head <sha>` comment, recording a `/code-review` run that found nothing.
- **A verdict** is `/review-work`'s verdict, posted as a PR comment starting `<!-- review-work:verdict ready -->` or `<!-- review-work:verdict not-ready -->`.
- **Addressed.** A pass is addressed when every thread it opened is resolved or its newest comment is an `/address-feedback` reply (starting `<!-- address-feedback:reply -->`). A verdict is addressed when it's `ready`, when a later `<!-- address-feedback:verdict-reply <id> -->` comment answers it, or when a later verdict replaces it.
- **Expected passes**: 1 when every issue the PR closes is `small`, else 2. A clean pass on the current head ends the countdown; a push after it reopens it.

## PR body format

**Write these two sections in the commit message body, not the GitHub web form.** `gh pr create --fill` takes the PR title from the commit subject and the body from the commit message, so the rationale stays in `git`, greppable via `git log`.

```markdown
## Plan

<What this does and why, with enough rationale that a reviewer doesn't have
to re-derive design decisions: why an approach/API/default was chosen, what
alternatives were ruled out and why.>

## Test plan

- [x] <concrete check: `make test`, a named test, or a manual step on a device or simulator>
- [x] ...
```

`make ship` owns the rest of the message. It replaces the subject with the issue's title (template prefix like `[Task]: ` stripped) and adds `scripts/issue-block.sh`'s block between your text and the trailer paragraph:

```markdown
<!-- ship:issue #<n> -->
## Issue #<n>: <title>

<the issue's ### What needs to be built, verbatim>

### Done when (from #<n>)
<the issue's Done-when items>

Closes #<n>
<!-- /ship:issue -->
```

So write only the Plan, the Test plan, `Closes #<n>` and the trailers. Each ship regenerates the block from the issue as it stands. Keep the "why" in the commit message, not in code comments: comments explain non-obvious *invariants*, not the history of a feature.

### Amending keeps the sections

`## Plan` and `## Test plan` start with `#`, so git's default `strip` cleanup deletes them whenever git opens the message for editing. Amend one of two ways:

- **Message unchanged:** `git commit --amend --no-edit`.
- **Message changed:** write it to a file and commit from it; `-F` gets `whitespace` cleanup and keeps every line:

  ```sh
  git log -1 --format=%B > "$SCRATCH/msg"   # a session scratchpad, not /tmp
  # edit "$SCRATCH/msg"
  git commit --amend -F "$SCRATCH/msg"
  ```

Never use a bare `git commit --amend` or `git commit -c`. As a backstop, `make hooks` sets `commit.cleanup=scissors`.

## Roadmap checklist convention

When a [ROADMAP.md](ROADMAP.md) item is finished, check it off **in the same commit as the work**, annotated with the closing issue:

```markdown
- [x] Rename the app target and bundle identifier: DONE; see #21
```

## Issues and labels

- Templates in `.github/ISSUE_TEMPLATE/`: **Roadmap task** (`[Task]: `, its stage dropdown is every `## ` heading of ROADMAP.md, in order), **Design decision** (`[Decision]: `), **Bug** (`[Bug]: `), **Feature request** (`[Feature]: `, refined into one of the others before it can be Ready).
- **`Ready`** means the design is settled and the Done-when names what proves it: a test (`SharedPetsTests/…`), a `make` target, or a `Manual check:` (`.claude/skills/file-task/done-when.jq`). `make ready N=<n>` adds it and drops `proposed` in one edit, refusing an issue with an open blocker or no such proof; `.github/workflows/issue-triage.yml` drops `proposed` when `Ready` is added in the web UI.
- **`proposed`**: filed by Claude, awaiting operator triage. Nothing picks it up until it's `Ready`.
- One label per roadmap stage: `s0`, `m0`, `m0.5`, `m1` to `m4`, `tooling`.
- Dependencies are native blocked-by links, not prose.

## Build, lint & CI

- **`make build` / `make test`** run `xcodebuild` on the project's shared scheme (read from the project) and the first available iPhone simulator, with DerivedData under the gitignored `build/`, one per worktree. Override with `SCHEME=` or `DESTINATION=`. `xcbeautify`, when installed, condenses the log.
- **`make lint`** is `lint-swift` (swift-format `--strict` from the active Xcode toolchain, configured by `.swift-format`) plus `lint-sh` (shellcheck over every tracked shell script, its version pinned only in `.shellcheck-version`; a local shellcheck at that version runs, else the Docker image). `make fmt` applies swift-format in place.
- Plain Make, no task runner: macOS ships GNU Make 3.81, so the Makefile avoids 3.82+ features like `.SHELLFLAGS`.
- The scripts need **bash 4+** (`brew install bash`), `jq` and an authenticated `gh`. macOS's `/bin/bash` is 3.2.
- **CI** (`.github/workflows/ci.yml`) runs `build-test` and `lint` on macOS runners and `lint-sh` on Linux, on every PR and push to `main`; `pr-shape.yml` adds `one-commit` on PRs. All four are required status checks on `main`, with strict mode on, so a PR merges only after CI ran against current `main`. That works with one-commit only because branches are **rebased, never merge-updated**: use "Update with rebase", never the default "Update branch".
- **CI's Xcode is the runner image's default**, which lags local Xcode: on 2026-11-11 `macos-26` had Xcode 26.6 (iOS 26 simulators only) while local was Xcode 27.0. So the deployment target must stay one CI's Xcode can simulate (26.x for now), and a project feature that only Xcode 27 opens breaks `build-test`. `ci.yml` prints `xcodebuild -version` first.
- **`auto-rebase.yml`** rebases auto-merge PRs that fell behind `main`, using the `REBASE_BOT_PAT` secret (a fine-grained PAT: contents, pull-requests and workflows write on this repo), because a `GITHUB_TOKEN` push starts no checks. Without the secret it does nothing.
- **`review-state.yml`** syncs the review-state labels. It is not a required check and must not become one.
- Never require a check whose workflow has a `paths:` filter: a workflow skipped by a path filter reports no status, so the PR stays pending forever. (A job skipped by `if:` reports `skipped`, which satisfies the rule.)
