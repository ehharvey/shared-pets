.PHONY: build test lint lint-swift lint-sh fmt clean hooks ship lgtm ready wt wt-list wt-gc

PROJECT := shared-pets.xcodeproj
# The app's one shared scheme. Read from the project rather than spelled here,
# so the rename in M0 (shared-pets -> SharedPets) needs no edit. Override with
# `make test SCHEME=...`.
SCHEME ?= $(shell xcodebuild -list -json -project $(PROJECT) 2>/dev/null | jq -r '.project.schemes[0] // empty')
# The first available iPhone simulator, by UDID, so the same command works on
# any Xcode and on CI's runner image. Override with
# `make test DESTINATION='platform=iOS Simulator,name=iPhone 18 Pro'`.
DESTINATION ?= id=$(shell xcrun simctl list devices available -j | jq -r '[.devices | to_entries[] | select(.key | test("iOS")) | .value[] | select(.name | startswith("iPhone"))] | first | .udid // empty')
# Build products stay inside the checkout (gitignored), one per worktree, so
# parallel worktrees never share or clobber DerivedData.
DERIVED := build/DerivedData
XCODEBUILD := xcodebuild -project $(PROJECT) -scheme "$(SCHEME)" -destination "$(DESTINATION)" -derivedDataPath $(DERIVED)
# xcbeautify, when installed, turns xcodebuild's log into one line per step and
# the failures; without it the raw log is printed. Recipes set pipefail so the
# exit code is xcodebuild's (macOS make is 3.81, which has no .SHELLFLAGS).
PRETTY := $(if $(shell command -v xcbeautify 2>/dev/null),| xcbeautify --quieter,)
# Every tracked Swift file, listed by git so worktrees under .claude/worktrees/
# and build output are never formatted or linted.
SWIFT_FILES = $(shell git ls-files '*.swift')
SHELLCHECK_IMAGE := koalaman/shellcheck:$(shell cat .shellcheck-version)

build:
	set -o pipefail; $(XCODEBUILD) build $(PRETTY)

test:
	set -o pipefail; $(XCODEBUILD) test $(PRETTY)

# swift-format from the active Xcode toolchain, so `make lint` here and CI's
# lint job run the version that ships with the Xcode they use. --strict makes
# warnings fail, so a file `make fmt` would change fails lint.
lint: lint-swift lint-sh

lint-swift:
	xcrun swift-format lint --strict --parallel $(SWIFT_FILES)

# shellcheck over every tracked shell script; needs Docker (scripts/lint-sh.sh).
lint-sh:
	SHELLCHECK_IMAGE=$(SHELLCHECK_IMAGE) ./scripts/lint-sh.sh

fmt:
	xcrun swift-format format --in-place --parallel $(SWIFT_FILES)

clean:
	rm -rf build/

# Relative path on purpose: it resolves per worktree (see .githooks/run-own-copy.sh).
# commit.cleanup=scissors keeps `## Plan` / `## Test plan` through an amend
# (DEVELOPMENT_CONVENTIONS.md § Amending keeps the sections). The identity is
# the noreply address every commit must use (§ Branching & issues).
hooks:
	git config core.hooksPath .githooks
	git config commit.cleanup scissors
	git config user.name "Emil Harvey"
	git config user.email "36806437+ehharvey@users.noreply.github.com"

ship:
	./scripts/ship.sh

# make lgtm  /  make lgtm PR=123
lgtm:
	./scripts/lgtm.sh $(PR)

# make ready N=13  /  make ready N="13 14": add Ready and drop proposed in one
# edit, refusing an issue with an open blocker (scripts/ready.sh). Each word is
# quoted, so the shell doesn't read N=#13 as a comment.
ready:
	./scripts/ready.sh $(foreach n,$(N),'$(n)')

# One worktree per issue, outside the operator's checkout (scripts/worktree.sh).
# `make wt N=13` prints the path; @ keeps it the only stdout line.
wt:
	@./scripts/worktree.sh new $(N)

wt-list:
	@./scripts/worktree.sh list

wt-gc:
	@./scripts/worktree.sh gc
