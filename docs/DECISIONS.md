# Decisions

Resolved design decisions, numbered so issues, commits and code can cite them as `§N`. Each section states the **current** rule; when a decision changes, rewrite it in place and add a dated entry to its `### History` (see [Development Conventions § Supersede in place](DEVELOPMENT_CONVENTIONS.md#supersede-in-place)). Open questions live in [Open Questions](OPEN_QUESTIONS.md) until they're decided here.

`grep -n '^## ' docs/DECISIONS.md` is the index.

## 1. The tooling roadmap stays as written

The Tooling section of [ROADMAP.md](ROADMAP.md) (T1 to T6) is built alongside M0 and M1, not deferred until after M1. `.claude/findings/` stays as the findings log.

Why: the tooling isn't greenfield. Most of it is adapted from [ehharvey/homelab-ops](https://github.com/ehharvey/homelab-ops), where the friction it addresses has already shown up, so building it early costs less than writing it from scratch would.

### History
- 2026-10-16: decided in #1, which proposed a minimal T1 and moving T3 to T5 after M1, and was closed as not planned.

## 2. The repo is public; CI runs on GitHub-hosted runners

The repo is public. Build, test and lint run in GitHub Actions (`.github/workflows/ci.yml`), with build, test and swift-format on macOS runners and shellcheck on Linux. The main ruleset requires `one-commit`, `build-test`, `lint` and `lint-sh`.

Why: on a private repo on the free plan, rulesets aren't available at all (the API returns 403) and macOS minutes are billed at about ten times the Linux rate, which is why the plan was to split CI between Linux runners and Xcode Cloud. Public repos get rulesets and free standard runners, macOS included, so one CI system covers everything and the Xcode Cloud split isn't needed. Xcode Cloud stays an option for TestFlight delivery (M4), not for PR checks.

Every commit on `main` uses GitHub's noreply address (`36806437+ehharvey@users.noreply.github.com`), since history is public. The history from before going public was rewritten to that address before the switch.

### History
- 2026-11-11: made public. The three earlier commits' personal address was rewritten to the noreply address first, and PRs #20 and #21, closed by the rewrite, were reopened as #22 and #23. This supersedes the CI split in ROADMAP.md § T1 and the billing and Xcode Cloud rows of § S0.
