---
name: release
description: Cut a new version of sketchup-mcp from conventional commits. Bumps version in all 4 files, rebuilds the .rbz, commits, and tags. Optional argument: major|minor|patch to force a level. Never pushes automatically.
---

# release

Cut a new version of the sketchup-mcp project. The version is locked across the SketchUp extension and the Python server (lockstep).

## Optional argument

`/release` — auto-decide level from conventional commits since the last tag.
`/release major|minor|patch` — force the level, skip commit parsing.

## Step-by-step

### 1. Pre-flight

- Abort if the working tree has uncommitted changes (`git status --porcelain` non-empty). Tell the user to commit or stash, then re-run.
- Read the current version from `server/pyproject.toml` (line `version = "X.Y.Z"`).
- Verify it matches in:
  - `extension/su_mcp.rb` → `extension.version     = "X.Y.Z"`
  - `extension/extension.json` → `"version": "X.Y.Z"`
  - `extension/package.rb` → `VERSION  = "X.Y.Z"`
- If any disagree, **stop and surface the discrepancy** — ask which is the source of truth before proceeding.

### 2. Determine the bump

If the user passed `major`/`minor`/`patch`, use that and skip to step 4.

Otherwise:
- Find the latest tag: `git tag --list 'v*' --sort=-v:refname | head -1`.
- If a tag exists, list commits since that tag: `git log <tag>..HEAD --pretty=format:"%H %s"`.
- If no tag, list all commits.
- Parse conventional commit prefixes (subject line):
  - `feat!:` or body contains `BREAKING CHANGE:` → MAJOR
  - `feat:` / `feat(scope):` → MINOR
  - `fix:` / `fix(scope):` → PATCH
  - `chore`, `docs`, `refactor`, `style`, `test`, `build`, `ci`, `perf` → no bump
- The bump level is the **highest severity found**.

### 3. Pre-1.0 rule

If the current version starts with `0.`:
- A would-be MAJOR bump becomes MINOR instead.
- Stay in 0.x until the user explicitly asks for 1.0.

### 4. Handle "no bumpable commits"

If the parsed commits warrant no bump (only chore/docs/refactor/etc), ask the user:
- (a) force PATCH, or
- (b) cancel.

### 5. Apply the bump

Compute new version. Update all 4 files using exact-match Edits:

| File | Pattern |
|---|---|
| `server/pyproject.toml` | `version = "OLD"` → `version = "NEW"` |
| `extension/su_mcp.rb` | `extension.version     = "OLD"` → `extension.version     = "NEW"` |
| `extension/extension.json` | `"version": "OLD"` → `"version": "NEW"` |
| `extension/package.rb` | `VERSION  = "OLD"` → `VERSION  = "NEW"` |

### 6. Rebuild the .rbz

```bash
cd extension && rm -f su_mcp_v*.rbz && ruby package.rb
```

Confirm `su_mcp_vNEW.rbz` exists. If the build fails: revert all 4 file edits and abort.

### 7. Commit + tag

- Stage **only the 4 modified files**. The `.rbz` is gitignored — do not stage it.
- Commit message: `chore(release): vNEW`
- Create annotated tag: `git tag -a vNEW -m "Release vNEW"`
- If a tag `vNEW` already exists locally or remotely, abort and tell the user.

### 8. Report

Show the user:
- `OLD → NEW` and the bump level
- Which commits drove the level (subject lines)
- The 4 files updated
- Path to the new `.rbz`
- The tag created

End with the push command, but **do not run it**:
```
git push origin main && git push origin vNEW
```

## Constraints

- Never push automatically.
- Never use `--no-verify` or `-i`.
- Never amend an existing release commit. If a release went wrong, ask the user whether to delete the tag and retry — don't assume.
- Always leave the working tree clean if anything fails (no half-done state).
- The `.rbz` is built on every release but never committed — it's a build artifact.
