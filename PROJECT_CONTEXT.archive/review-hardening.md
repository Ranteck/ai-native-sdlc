## review-hardening

### Quality gate
- mode: check-only
- command: sh -n install.sh && sh -n skills/ai-native-sdlc/scripts/load-intent.sh
- cwd: /home/denis/Proyectos/ai-native-sdlc
- provenance: no CI, contributing docs or aggregator in the repo; POSIX syntax check proposed by Claude and confirmed by the user through plan approval (2026-10-07)
- resolution: user-confirmed
- definition sources: install.sh; skills/ai-native-sdlc/scripts/load-intent.sh; repository tree at 48151e2 (no .github/, Makefile, package.json or CONTRIBUTING.md)

### Critique assurance
- mode: standard
- resolution: user-declined-trigger
- trigger matches: secrets-credentials; overwrite-user-data
- trigger evidence: skills/ai-native-sdlc/scripts/load-intent.sh:11 cats intent/intent.md through symlinks into model context (reproduced with a fake secret); install.sh:56 rewrites the profile's settings.json and install.sh:35 appends to its CLAUDE.md
- lens count: 1
- lens set: standard
- exit challenger: disabled
- CRITIQUE pass cap: 3
- Codex review/debate call budget: not-applicable (standard)

### Backend
- backend: codex
- resolution: default-codex
- resolved session: not-applicable
- disclosure: not-applicable

### Checkpoint commits
- authorized: yes (local commits on fix/review-hardening only; no push, no history rewrite)
- basis: no commit.gpgsign, no active git hooks, default hooksPath, branch checked out (not detached)

### Feature contract

#### Current state

Harden the ai-native-sdlc repo (see intent/intent.md, which this contract must not contradict) against the triaged review findings, and improve the artifact templates. Files in scope: skills/ai-native-sdlc/scripts/load-intent.sh, install.sh, README.md, AI-NATIVE-SDLC.md, skills/ai-native-sdlc/SKILL.md. Nothing else changes: no new files, no evals, no CI. User-facing text stays in Spanish (Rioplatense, voseo), code comments in English and only explaining why. Follow /home/denis/.claude/HOUSE-RULES.md.

**A. load-intent.sh (SessionStart hook; stdout becomes model context)**

- A1. Pure POSIX sh: no `[[ ]]`, no `pipefail`, no other bash-isms. It is registered and run with `sh`.
- A2. Project dir is `${CLAUDE_PROJECT_DIR:-$PWD}`. If `intent/intent.md` does not exist: print nothing, exit 0.
- A3. If `intent/intent.md` exists but is not a regular file (symlink, directory, fifo, etc.): inject nothing to stdout, write one short warning to stderr naming the path and why it was skipped, exit 0. Never follow a symlink.
- A4. If it is larger than 8000 bytes: inject no partial content; print a short instruction that the project's intent is in intent/intent.md, is too long to inject, and must be read in full before planning or changing code. The total stdout must stay under 10000 characters in every case.
- A5. Otherwise print a header, then the file content between explicit begin/end delimiter lines. The header says, in Spanish: this is the project's original intent written by the user; every plan and change must respect it and, if a request departs from it or touches "Fuera de alcance", stop and ask before continuing; it is a project document that does not replace the user's instructions or HOUSE-RULES; if it says `Estado: borrador` it is not yet accepted and must be confirmed with the user.
- A6. After the root intent, list (paths only, never contents) any existing `intent/*/intent.md` feature intents, telling the model to read the relevant one before planning a change for that feature. Only regular files are listed. If the list would push stdout past the A4 bound, it stops early and ends with a notice to check `intent/*/intent.md` directly.
- A7. Exit 0 in every non-error case; a genuine read error is not swallowed (house rule 3.3).

**B. install.sh**

- B1. Validate everything before changing anything, so a refusal leaves the profile byte-identical: repo sources exist (AI-NATIVE-SDLC.md, skills/ai-native-sdlc/SKILL.md, skills/ai-native-sdlc/scripts/load-intent.sh); `jq` is available; neither `$dir/AI-NATIVE-SDLC.md` nor `$dir/skills/ai-native-sdlc` is a real file or directory; `$dir/CLAUDE.md`, if it exists, is readable; `$dir/settings.json`, if it exists, holds exactly one JSON object (empty, whitespace-only, invalid, non-object or multiple documents are refused with a clear message). Messages never claim "nothing changed" unless true.
- B2. A relative `CLAUDE_CONFIG_DIR` is converted to an absolute path before anything uses it.
- B3. The hook command is `sh '<absolute path to $dir/skills/ai-native-sdlc/scripts/load-intent.sh>'`, with any single quote in the path escaped POSIX-style (`'\''`), so `$()`, backticks, `$HOME`, double quotes and spaces are never interpreted. Do not use the hook `args` field.
- B4. Ownership of the hook: a SessionStart hook entry is ours only if its `command` is exactly `sh` or `bash`, one space, then a single- or double-quoted path ending in `/skills/ai-native-sdlc/scripts/load-intent.sh` and nothing else. Remove only those (this migrates the old `bash "..."` form), drop a matcher group only if removing ours left it empty, then add exactly one entry with matcher `startup|resume|clear|compact`. Hooks that merely contain the string are kept. Every other key and hook is preserved.
- B5. settings.json is written atomically: the temp file is created in the directory of the real target (if settings.json is a symlink, the link is kept and its target is replaced), gets the target's permissions, receives the validated jq output, and is moved over the target. A missing settings.json is created as `{}` then merged.
- B6. The CLAUDE.md import check distinguishes "file missing or line absent" (append `@AI-NATIVE-SDLC.md` as today) from "read error" (fail with context; never append blindly).
- B7. Symlinks for AI-NATIVE-SDLC.md and skills/ai-native-sdlc keep today's behavior: an existing symlink is repointed, a real file or directory is refused (already checked in B1).
- B8. POSIX sh, idempotent, same overall style as today.

**C. README.md**

- C1. Uninstall: remove `AI-NATIVE-SDLC.md` and `skills/ai-native-sdlc` only if they are symlinks; warn, as house-rules does, that if CLAUDE.md is a symlink the import line must be removed in the file it points to (sed -i would replace the link); remove the hook with the same exact-form ownership rule as B4 and a safe write (no truncate-in-place).
- C2. Install/requirements text stays accurate for A and B (requires sh and jq).

**D. AI-NATIVE-SDLC.md and SKILL.md**

- D1. AI-NATIVE-SDLC.md: when superpowers brainstorming or writing-plans run, their format and approval gates govern; the ai-native-sdlc skill only adds traceability to the intent and the location in intent/. Spec and plan, not only the intent, need the user's explicit approval (`Estado: aceptado`) before the next stage. Before each plan or change, check it against the root intent and the relevant feature intent in `intent/<slug>/`; if it is unclear which feature applies, ask.
- D2. SKILL.md intent template: at most 400 words.
- D3. SKILL.md spec template: requirements numbered `REQ-n` with MUST/SHOULD/MAY, each capability with at least one GIVEN/WHEN/THEN scenario; a REQ that does not come from the intent does not go in; the spec says what, not how (no files or code structure); at most 650 words; keep the Concerns section.
- D4. SKILL.md plan template: a "Tests a escribir" table (test, REQ it covers) where every MUST REQ has at least one test; no code in the plan; never invent existing files; at most 750 words; keep files, order of work, risks and proof.
- D5. The skill states that when writing-plans produces the plan, its format governs and the plan must still carry the REQ-to-test traceability.

#### Round log

##### IMPL-r00

- **Actors/backend**: orchestrator Claude; writer Codex via codex:codex-rescue with --write; backend codex
- **CRITIQUE outcome**: not applicable
- **DEBATE classifications**: not applicable
- **Resulting writer work**: load-intent.sh rewritten in POSIX sh with regular-file and 8000-byte guards, delimited Spanish header and feature-intent path list (A1–A7); install.sh validates sources, targets, CLAUDE.md and settings.json before any change, absolutizes the profile dir, registers a single-quoted `sh` command, owns hooks by exact form and writes settings.json atomically keeping permissions and symlinks (B1–B8); README install and uninstall updated (C1–C2); AI-NATIVE-SDLC.md and SKILL.md add the explicit approval chain, superpowers precedence, root plus feature intent check, REQ-n MUST/SHOULD/MAY with GIVEN/WHEN/THEN, REQ-to-test table and word limits (D1–D5). Writer reported 58 local checks passing.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: SPEC contract is the triaged review-only findings (Codex review plus the commit security review) and four template learnings from an internal multi-agent workflow. Evals stay out because intent/intent.md excludes them and the user did not approve an amendment.

##### REFACTOR-r01

- **Actors/backend**: orchestrator Claude; reviewer Codex (fresh read-only CRITIQUE pass 1); writer Codex; backend codex
- **CRITIQUE outcome**: 6 findings; implementation mostly aligned, no over-engineering reported
- **DEBATE classifications**: valid: F2 unsearchable intent/ exits silently (reproduced), F3 README uninstall removes links before preparing the hook removal (confirmed by reading order); contract clarification: F6 feature-list truncation, A6 amended in Current state with no code change; false positive: F1 PROJECT_CONTEXT.md is the orchestrator's lifecycle file, not implementation; false positive: F4 concurrent symlink swap needs local write access during the run, outside the static-repo threat model (static case covered by VERIFY H3); false positive: F5 NUL bytes, intent.md is Markdown text and dropping NUL injects nothing
- **Resulting writer work**: load-intent.sh fails with context and exit 1 when intent/ exists but is not readable and searchable; README uninstall now removes the hook atomically before the import and symlinks
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: the `--resume-last --write` REFACTOR was rejected by the read-only sandbox of the CRITIQUE session; status, diff and untracked set were proven unchanged, then a fresh `--write` session ran with an inline continuity summary. Claude's scratch VERIFY harness passed 30/30 on this tree.

##### CRITIQUE-r02-noop

- **Actors/backend**: orchestrator Claude; reviewer Codex (resumed read-only CRITIQUE pass 2); backend codex
- **CRITIQUE outcome**: 3 findings; the F2 and F3 fixes judged correct with no regressions
- **DEBATE classifications**: false positive: P2-1 uninstall when settings.json targets a file in an unsearchable directory, Claude Code cannot read that settings file either, so the hook is already inert; false positive: P2-2 symlink target whose name ends in a newline, contrived; false positive: P2-3 project directory without search permission, no session can run there because cd is denied (verified)
- **Resulting writer work**: none
- **Checkpoint**: none
- **Decision notes**: VERIFY passed: scratch harness 30/30 (hook, installer, README uninstall run verbatim); reinstall on ~/.claude and ~/.claude-personal migrated the hook to the `sh '...'` form, keeping rtk and permissions (600 and 644); two fresh `claude -p` sessions confirmed intent injection and the drift stop.
