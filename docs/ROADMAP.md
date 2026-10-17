# Roadmap

Each app milestone (M0 to M4) should end with a build that runs on a real iPhone. The exceptions are S0 and the Tooling section. They change docs, scripts, CI, and Claude Code setup, not the app, so they end with their own "Done when" checks instead.

## S0: Verify assumptions (first)
The planning docs rely on these claims. They were stated from memory during planning and have not been checked. Confirm or correct each one before building on it. Record the result here and fix any doc that depends on a wrong claim.

| Claim | Depends on it | How to check |
|---|---|---|
| App Store Connect sandbox testers cannot sign in to iCloud, so testing sharing needs a second real Apple Account. | [Testing Shared Sync](TESTING_SHARED_SYNC.md), M0 test account | Try signing a simulator into iCloud with a sandbox tester. Check Apple's sandbox testing docs. |
| Simulators on Apple silicon Macs receive CloudKit change notifications. | Testing Shared Sync device table, `/verify-sync` | Run a minimal CloudKit subscription on two signed-in simulators and watch for the push. |
| macOS runner minutes count ten times against GitHub's free allowance on private repos. | T1 CI split | Check GitHub's current Actions billing docs. |
| Xcode Cloud includes 25 free compute hours a month with the Apple Developer Program, and reports status checks to GitHub PRs. | T1 CI split | Check Apple's current Xcode Cloud docs. Connect the repo and open a test PR. |
| Xcode's MCP tools only see the project open in Xcode, so they don't see changes in a git worktree. | T1 `CLAUDE.md` worktree rule, `issue-worker` | Open the main checkout in Xcode, change a file in a worktree, and ask the Xcode tools for diagnostics on it. |

- [ ] Sandbox testers and iCloud.
- [ ] Simulator CloudKit notifications.
- [ ] GitHub macOS runner billing.
- [ ] Xcode Cloud free hours and GitHub status checks.
- [ ] Xcode MCP tools and worktrees.

## M0: Foundations
- [ ] Rename the app target and bundle identifier from the template.
- [ ] Set up folder structure: Models, Features, Services, Resources.
- [ ] Add a unit test target with Swift Testing.
- [ ] Enable the iCloud capability with a CloudKit container.
- [ ] Create a second Apple Account for testing. See [Testing Shared Sync](TESTING_SHARED_SYNC.md).

## Tooling: Claude Code workflow (alongside M0 and M1)
Not app features. Claude Code automation for the issue and PR workflow, modeled on [ehharvey/homelab-ops](https://github.com/ehharvey/homelab-ops). Each group depends on the one before it.

### T1: Workflow foundation
Skills point at these for the rules instead of restating them.
- [ ] `CLAUDE.md` with conventions, commands, worktree rules, and context-lean rules.
- [ ] Note in `CLAUDE.md` that Xcode's MCP tools see the project open in Xcode, which is the main checkout. Worktree sessions must check their work with command-line `xcodebuild`.
- [ ] Make targets or scripts: `build`, `test`, `lint`, `fmt`, `ship`, `lgtm`, `wt`, `wt-gc`, `hooks`.
- [ ] `.githooks/pre-push` that refuses more than one commit on an issue branch.
- [ ] GitHub: rebase-only merges on `main`, and a required `one-commit` PR-shape check.
- [ ] Issue templates: task, design decision, bug.
- [ ] Labels: `task`, `Ready`, `proposed`, `design-decision`, `bug`, `documentation`, `ai-optimization`, one per roadmap stage.
- [ ] `docs/DECISIONS.md` with numbered sections, so issues and code can cite `§N`.
- [ ] CI on Linux runners: PR shape and swift-format lint. macOS minutes count ten times against the free allowance on private repos.
- [ ] CI in Xcode Cloud: build and test on every PR, reporting status checks to GitHub. Uses the included free compute hours.

### T2: Core issue loop
- [ ] `/file-task`: file an issue in the task template's shape, with labels and native blocked-by links. "Done when" names the test, UI test, or manual check that proves the work.
- [ ] `/next`: one bounded report of Ready issues, blockers, unchecked roadmap items, open PRs, and in-flight branches, then a short recommendation.
- [ ] `/ship-issue`: one commit, a Plan and Test plan in the commit body, roadmap check-off in the same commit, then fmt, build, test, lint, and `make ship`. Stops before `make lgtm`.

### T3: Review loop
- [ ] `/address-feedback`: gather unresolved review threads and failing checks, amend the single commit, re-verify, re-ship, sync the PR body, and reply on each thread. Stops before `make lgtm`.
- [ ] `/review-work` (operator-invoked only): shared audit script, "Done when" matched to evidence, and app-specific checks. Examples: entitlement or Info.plist changes, CloudKit schema changes not in the architecture doc, and new strings missing from the String Catalog.
- [ ] `test-runner` agent: runs `xcodebuild` builds and tests and returns pass or fail per test with only the failing log lines.
- [ ] `issue-worker` agent: implements one issue in its own worktree and hands back a committed branch with a short report and a Noticed list.

### T4: Decisions
- [ ] `/refine-issue`: take a stub issue toward Ready. Classify it, set blockers, ask the open design questions, rewrite the body, and report each change with its revert command.
- [ ] `/record-decision`: turn a resolved question into a numbered section in `docs/DECISIONS.md`, remove its row from [Open Questions](OPEN_QUESTIONS.md), and update docs that cite it.

### T5: Session review hook
Goal: each Claude Code session leaves behind findings. A finding may or may not become a GitHub issue. Nothing is filed automatically. The operator decides.

How it works:
1. A `SessionEnd` hook in the project's `.claude/settings.json` runs a small script. The hook input includes the session transcript path and the end reason.
2. The script returns right away and starts a headless `claude -p` review in the background. The session is closing, so the review cannot run inside the hook's time limit.
3. The reviewer reads the transcript and writes each finding as its own JSON file in [`.claude/findings/`](../.claude/findings/README.md). The schema there is the source of truth.
4. A `/triage-findings` skill walks the open findings with the operator. Approved ones are filed through `/file-task`, without the `proposed` label because the operator asked for them. Each finding gets a new status and a `statusReason`: `filed`, `folded` into an existing issue, or `dismissed`.
5. The skill commits the new and changed finding files as one commit on a `findings/<date>` branch and ships it as a PR, following the one-commit rule.

Findings log rules:
- **One JSON file per finding.** Files are named by UTC timestamp, short session ID, and sequence number. Writers create a temporary file and rename it into place, and never overwrite. Parallel sessions cannot clobber each other.
- **Never delete a finding.** A finding that is not acted on gets `status: "dismissed"` with a `statusReason`. Every status change is appended to the finding's `history`.
- **One inbox for all worktrees.** The hook writes new findings as untracked files in the main checkout's folder, found from the git common directory. Triage moves them into its PR branch.
- **Committed.** Findings live in the repo and reach `main` only through triage PRs. CI rejects deleted finding files and files that fail the schema.
- **Safe to commit.** Evidence excerpts must not include secrets, tokens, credentials, or personal data.

Finding categories:
- **Bug** noticed outside the session's issue.
- **Doc drift**, where docs and code disagree.
- **Unrecorded decision**, where something was settled in chat but not written into the docs.
- **Workflow friction**, such as a missing skill, a skill step that failed, a repeated permission prompt, or a large tool output that wasted context.
- **Follow-up** work that was deferred during the session.

Guards:
- **No recursion.** The background review sets an environment variable, and the hook exits early when it sees it.
- **Skip trivial sessions.** Skip sessions below a minimum transcript size, and skip ends caused by `/clear` with almost no work.
- **No duplicates.** The reviewer checks open issues and all existing findings, including dismissed ones, before writing.
- **Bounded cost.** The reviewer uses a smaller model with a turn limit. It reads the transcript in slices, not whole.

Work items:
- [x] Findings folder, README, and JSON Schema in `.claude/findings/`.
- [ ] Hook script with the recursion, size, and reason guards.
- [ ] Reviewer prompt with the categories, evidence rules, and schema. It validates each file before renaming it into place.
- [ ] `/triage-findings` skill that files through `/file-task`, updates status, `statusReason`, and history, and ships the one-commit findings PR.
- [ ] CI check on Linux: every finding validates against the schema, and no finding file is deleted or renamed.
- [ ] Document the hook and the triage loop in `CLAUDE.md`.
- [ ] Done when: ending a real session produces schema-valid findings within a few minutes. A `/clear` on an empty session produces nothing. The review's own session does not trigger a second review. One finding goes from triage to a filed issue, and one to dismissed with a reason. Both reach `main` through a findings PR with green checks.

### T6: App-specific skills
- [ ] `/verify-sync`: run the [shared sync checklist](TESTING_SHARED_SYNC.md) on two simulators. A simulator not signed in to iCloud is a skip, not a failure. Build alongside M0.5.
- [ ] `/cut-release` (operator-invoked only): bump the build number, confirm the CloudKit schema is deployed to Production, and tag the TestFlight build. Build before M4.

### Deferred
- `/run-chain`: work through the Ready queue from one root session with parallel `issue-worker`s. Revisit after M1, once the single-issue loop is proven.
- `decisions-scout` agent: brief workers on binding decisions. Add when `docs/DECISIONS.md` grows past about 20k tokens.

## M0.5: Shared sync spike (timebox: 3 days)
CloudKit sharing itself is proven. This spike checks our specific combination before the data model is locked in M1. The code is throwaway.

Goal: prove the shape of the sync layer, not build it.
- [ ] Owner creates a household zone with one Pet and one Completion record.
- [ ] Owner shares the zone with `CKShare`. Participant accepts it through the scene delegate.
- [ ] Both accounts write Completion records with `CKSyncEngine`. Both see each other's records.
- [ ] Two near-simultaneous completions both survive.
- [ ] A change notification reaches the other device.
- [ ] Decide how SwiftData models map to CloudKit records, or whether to drop SwiftData for a simpler local store.

Exit criteria: write the findings into [Architecture](ARCHITECTURE.md). If the spike fails, fall back to Core Data with `NSPersistentCloudKitContainer` sharing.

## M1: Solo habit tracker (local only)
- [ ] SwiftData models for Habit and Completion.
- [ ] Recurrence enum and "is due on date" logic with tests.
- [ ] Today screen listing due habits with a check-off action.
- [ ] Create and edit habit form, including care act choice.
- [ ] Local reminder notifications.

## M2: Pet prototype (local only)
- [ ] Pet model with needs and decay logic, fully unit tested.
- [ ] Shih Tzu art prototype with idle, happy, sad, and messy states.
- [ ] Care act animations for Feed, Walk, Groom, Play.
- [ ] Pet home screen that reacts to completions.

## M3: Shared raising
- [ ] Build the production sync layer using the M0.5 findings.
- [ ] Create a household and invite members with `CKShare`.
- [ ] Sync habits, completions, and pet state across members.
- [ ] Contribution feed.
- [ ] Nudges via CloudKit subscriptions, rate limited to one per member per day.

## M4: Polish and TestFlight
- [ ] Onboarding: name your pet, create your first habit, invite someone.
- [ ] Pet growth rewards: tricks and grooming styles.
- [ ] Accessibility pass: VoiceOver, Dynamic Type, contrast.
- [ ] TestFlight with a few real households.

## Later (optional)
- Apple Watch app and complications.
- iPad layout tuning.
- Widgets and Live Activities for the pet.
- macOS.
- More breeds.
