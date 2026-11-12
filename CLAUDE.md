# CLAUDE.md

Guidance for Claude Code working in this repo: Shared Pets, an iPhone-first SwiftUI habit tracker where habits become care acts for a shared pet. Context lives in `docs/`; read it **selectively**, since everything you read is carried, and paid for, on every later turn.

- `docs/PRODUCT.md`: what the app is for and its non-goals
- `docs/ARCHITECTURE.md`: stack, data model sketch, key design decisions
- `docs/ROADMAP.md`: current stage and status; check off items you complete. Read the current stage's section (`grep -n '^## ' docs/ROADMAP.md`), not the whole file
- `docs/DEVELOPMENT_CONVENTIONS.md`: the rationale behind the Conventions summary below. Read the relevant section before touching CI, the ruleset, the scripts or the ship flow
- `docs/DECISIONS.md`: resolved decisions, cited as `§N`. `grep -n '^## ' docs/DECISIONS.md` is the index; read only the sections an issue or file cites
- `docs/OPEN_QUESTIONS.md`: unresolved questions; don't build on one as if settled
- `docs/TESTING_SHARED_SYNC.md`: how to test CloudKit sharing across accounts and devices

## Keeping context lean and current

- **Bound every output**: `gh … --json … --jq`, `grep`/`tail` on logs, `sed -n` ranges on large files. `xcodebuild` logs are huge: tail them, grep for `error:` / `failed`, or install `xcbeautify`. When output is saved to a tool-results file for being too large, grep it; never read it whole.
- **Supersede in place; newest wins.** A decision's body and an issue's body state the current rule; history goes in a `### History` subsection or in issue comments. Where older text still stacks dated notes, the newest wins.
- **Verify claims before presenting them.** For Apple platform behaviour (CloudKit, SwiftData, entitlements), check Apple's docs or run a real probe; otherwise label the claim unverified. `docs/ROADMAP.md § S0` lists claims still unverified.
- **One issue per session.** After a PR ships, don't roll into the next issue in the same context. Post open questions as an issue comment, then suggest a fresh session.
- **Mechanics.** In a worktree session, run git as plain standalone commands. Wait on CI with `gh pr checks <n> --watch` in the background, not `sleep` loops.

## Commands

    make build   # xcodebuild build: shared scheme, first available iPhone simulator
    make test    # xcodebuild test (Swift Testing, SharedPetsTests)
    make lint    # swift-format --strict + shellcheck; run before declaring done
    make fmt     # swift-format in place

    make hooks   # once per clone: pre-push hook, commit.cleanup=scissors, noreply identity
    make ready N=<n>  # triage: add Ready + drop proposed; refuses a blocked issue or one with no Done-when proof

    make wt N=<n>  # worktree for issue #n on eharvey/#<n>; prints its path
    make wt-gc     # remove worktrees whose PR merged (make wt-list: dry run)

    make ship    # squash, rebase, copy the issue in, check the message, push, open the PR
    make lgtm    # enable auto-merge: the OPERATOR's call, never run it unless asked

Overrides: `make test SCHEME=SharedPets DESTINATION='platform=iOS Simulator,name=iPhone 18 Pro'`. The scripts need bash 4+ (`brew install bash`), `jq` and `gh`.

## Conventions (see docs/DEVELOPMENT_CONVENTIONS.md for detail and rationale)

- One branch per GitHub issue: `eharvey/#<n>`, landing as **exactly one commit**. `main` is rebase-only, so N branch commits become N commits on main. Enforced by `.githooks/pre-push` (`make hooks`) and the required `one-commit` check.
- Write the `## Plan` / `## Test plan` sections and `Closes #<n>` in the *commit message body*; `make ship` copies them into the PR. Don't close issues manually. Amend with `--no-edit` or `-F <file>`, never a bare `--amend` (it strips `## ` lines).
- Every commit uses `36806437+ehharvey@users.noreply.github.com`. The repo is public (§2); a personal address in a commit is published for good.
- `make ship` pushes and opens the PR, then stops. `make lgtm` enables auto-merge once the operator has read the diff. **Never run `make lgtm` or `gh pr merge` unless asked.**
- When a `ROADMAP.md` checklist item is finished, check it off in the *same* commit as the work, annotated `see #<n>`.
- Swift: SwiftUI and Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest, for unit tests. Folders: `SharedPets/Models`, `Features`, `Services`, `Resources`. Format with `make fmt`; `.swift-format` is the style.
- Keep the "why" in the commit message, not in code comments; comments explain non-obvious invariants.
- Never commit signing material, provisioning profiles, `xcuserdata/` or `build/`.

## Worktrees

- **The main checkout is the operator's.** It often holds uncommitted work or an open Xcode project. Don't edit, switch branches or commit there; every issue gets its own worktree: `make wt N=<n>`, then work from the printed path.
- **Run `make wt-gc` at the start of a session.** It removes worktrees, and their local branches, only when nothing can be lost (clean, and the PR merged at that commit, or no commits beyond main).
- **Xcode's MCP tools probably see only the project open in Xcode** (the main checkout), not your worktree. This is unverified (ROADMAP.md § S0, #12). Until it's checked, verify worktree changes with `make build` / `make test` from the worktree, and read the worktree's files rather than trusting Xcode diagnostics.
- Each worktree has its own `build/DerivedData`, so parallel builds don't collide; simulators are shared, so run one `make test` at a time.
- Hooks need no per-worktree setup: the main checkout's `pre-push` hands off to the pushing worktree's own copy (`.githooks/run-own-copy.sh`).

## Validating changes for real

Unit tests don't catch everything. CloudKit sharing, entitlements, push notifications and iCloud account state only show up on a real run. Before calling such work done, run it on a simulator or device signed in to iCloud, following `docs/TESTING_SHARED_SYNC.md`, and record what you observed in the commit's Test plan. A missing precondition (no iCloud account on the simulator) is a **skip**, said out loud, never a pass.

## Skills and agents

The tooling roadmap (`docs/ROADMAP.md § Tooling`, #11) adds skills (`/file-task`, `/next`, `/ship-issue`, `/address-feedback`, `/review-work`, `/refine-issue`) and agents in later groups. Until they exist, follow this file and `docs/DEVELOPMENT_CONVENTIONS.md` by hand. Skills point at those two files for the rules rather than restating them; change the rules there.
