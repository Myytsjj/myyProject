# OSC2026 Acceptance Remediation Implementation Plan

> **For agentic workers:** Execute this plan task-by-task with verification after each task.

**Goal:** Remove the documented OSC2026 acceptance gaps while keeping `Myytsjj` as the only identity used for new commits and leaving existing history untouched.

**Architecture:** Keep the current Markdown, SSG, CLI, and documentation boundaries. Add only a line-delimited front matter regression fix, make the README API example standalone, add a concise proposal and source URLs, and make line-ending behavior explicit for reproducible checks.

**Tech Stack:** MoonBit 0.10.4 toolchain, MoonBit tests, Markdown documentation, GitHub Actions, Git.

## Global Constraints

- Do not read or use cached credentials or historical account identities.
- Set new commit author identity explicitly to `Myytsjj`.
- Do not rewrite existing Git history or force-push.
- Do not claim Mooncakes `0.3.1` is published without a successful installation check.
- Preserve the existing public API unless the regression fix requires a behavior correction.

### Task 1: Submission Documentation

**Files:**
- Create: `docs/proposal.md`
- Modify: `README.md`
- Modify: `THIRD_PARTY_NOTICES.md`

- [ ] Add a concise proposal describing the actual Markdown-to-HTML and static-site-generator scope, users, core features, implementation type, GitHub link, and GitLink link.
- [ ] Make the README library example standalone by defining imports, source text, layout strings, configuration, and a `main` function.
- [ ] Add source URLs and explicit reference boundaries for every third-party project already named.
- [ ] Check all Markdown code blocks and links against the repository files.

### Task 2: Front Matter Boundary Regression

**Files:**
- Modify: `src/ssg/front_matter_contract_test.mbt`
- Modify: `src/ssg/ssg.mbt`

- [ ] Add a failing test proving that `---` must be an opening delimiter at the start of the first line and a closing delimiter on its own line.
- [ ] Run the focused SSG test and confirm the new assertion fails against the current parser.
- [ ] Implement the smallest line-based closing-delimiter search that preserves the existing supported front matter subset.
- [ ] Run the focused test and the complete MoonBit test suite.

### Task 3: Reproducible Repository Checks

**Files:**
- Create: `.gitattributes`
- Modify: `scripts/verify_acceptance.ps1`
- Modify: `docs/acceptance-checklist.md`

- [ ] Declare LF normalization for source and documentation files so Windows worktrees do not create false semantic diffs.
- [ ] Make the acceptance script distinguish unsupported strict flags from project failures.
- [ ] Record that `0.3.0` is installable while `0.3.1` remains release-pending until a real Mooncakes publish.
- [ ] Run the full acceptance command set and inspect Git diff, status, and generated interface changes.

### Task 4: Cross-Repository Verification

**Files:**
- Synchronize the committed files from GitHub to GitLink without rewriting either existing history.

- [ ] Verify MoonBit commands, CLI, examples, benchmark smoke, and the focused regression test on both worktrees.
- [ ] Compare committed file lists and file contents between the two default branches.
- [ ] Commit with explicit `Myytsjj` identity only after verification.
- [ ] Leave Mooncakes publishing and external release creation pending safe platform credentials.
