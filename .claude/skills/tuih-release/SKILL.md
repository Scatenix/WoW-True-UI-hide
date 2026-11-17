---
name: tuih-release
description: How True UI Hide releases are made (tag push triggers the GitHub Actions pipeline), what the workflow does, how to retry or undo a failed release, and how to prepare a release. Load when the maintainer wants to release, tag, bump the version, or when the Release workflow fails.
---

# Releasing True UI Hide

You never commit, tag or push. You prepare, explain, and give the maintainer the exact commands.

## Normal release
1. Everything wanted is committed and pushed to `main` by the maintainer. The tag must point at the LATEST `main` commit.
2. Maintainer: `git tag vX.Y.Z` then `git push origin vX.Y.Z` (version format `v1.2.3`; `v1.2.3-beta1` = pre-release; the tag check rejects anything else, e.g. `v.1.0` or `1.0`).
3. `.github/workflows/release.yml` runs (Actions tab):
   - job `lint`: installs `lua-check` (apt), runs `luacheck TrueUIhide` with `.luacheckrc`. Any warning fails the run (no release is created).
   - job `release`: validates the tag; sets `## Version: <tag>` in `TrueUIhide/TrueUIhide.toc`; commits "Release <tag>" on top of the tagged commit; `git push origin HEAD:main` (fast-forward only); moves the tag to the new commit (`git tag -f`, `git push -f origin refs/tags/<tag>`; tag pushes made with the default token do not re-trigger the workflow); builds `TrueUIhide-<tag>.zip` containing only the `TrueUIhide/` folder, with the repo-root `LICENSE` copied in as `TrueUIhide/LICENSE.txt` (README, .gitignore, `.github`, `.claude` and everything else are NOT in the zip); creates the GitHub release with generated notes (`--prerelease` when the tag contains `-`).
   - If the `.toc` version already equals the tag, no commit is made and the tag stays.
4. After the run the maintainer pulls and refreshes tags: `git pull` and `git fetch --tags --force`.

Pinned versions: `actions/checkout@v7`, `runs-on: ubuntu-24.04`. Bump them when GitHub announces deprecations (warnings show up in the run summary). A newer `ubuntu` image can rename the `lua-check` package: if the lint step fails at install time, fix the install line.

## When it fails
- Lint failure: fix code or `.luacheckrc` on `main`, push, then recreate the tag (the old tag points at the broken commit):
  `git tag -d vX.Y.Z` / `git push origin :refs/tags/vX.Y.Z` / `git tag vX.Y.Z` / `git push origin vX.Y.Z`.
- "tag must be on latest main" (push to main rejected): `main` moved after tagging. Pull, delete the tag locally and remotely, create it again.
- Release creation failed after the version commit was pushed: the commit and moved tag exist. Delete any half-made release on the GitHub releases page, delete the tag, `git pull`, and recreate the tag. The version line then already matches, so no second commit is made.
- Delete a test release completely: delete the release on GitHub, then delete the tag locally and remotely as above. Do tests with a pre-release tag such as `v0.9.0-beta1`.
- `git push origin <tag>` says "src refspec ... does not match any": the tag does not exist locally (usually a typo like `v.0.9.0`). Create it with `git tag <tag>` first, then push.

## Before suggesting a release
- Changes are committed by the maintainer, README is in sync, `luac -p` passes, no temporary debug code is left (grep for `dbg`).
- If the game version changed, the `## Interface:` number is correct (see `tuih-game-patch`); the workflow does not touch it.
- Nothing unverified in the game should go out silently: tell the maintainer what was only mock-tested.

## Related files
`.github/workflows/release.yml`, `.luacheckrc`, `.gitignore` (ignores zips and editor files), `LICENSE` (the only license file in the repo), README section "Releasing (for the maintainer)" (keep it in sync with the workflow).
