# opencode-sandbox

Custom image built on top of `ghcr.io/anomalyco/opencode` (v2.x.x) that adds a
node / python / go / git toolchain, published to GHCR so the local sandbox script
can pull it.

## What runs here

`.github/workflows/build.yml` runs every 6 hours (and on manual dispatch):

1. Resolves the highest opencode base tag `2.x.y` (numeric semver, not lexicographic).
2. If `ghcr.io/<owner>/opencode-sandbox:<version>` does not exist yet, builds it
   (`OPENCODE_VERSION=<version>`) and pushes `:<version>` and `:latest`.
3. Verifies the pushed image is **anonymously pullable** and fails the run if not.
4. Opens an issue if a new opencode major (3.x+) appears.

## One-time manual step after the first push

GHCR packages are **private by default**, even in a public repo. The pipeline's
"Verify anonymously pullable" step fails until you flip it:

> Repo → Packages → `opencode-sandbox` → Package settings → Change visibility → **Public**

## Forcing a rebuild of an existing version

The workflow is skipped when the version tag already exists. This is intentional
(rebuilds happen only when a new base tag appears). If you change the `Dockerfile`
and need to re-publish the same version, either:

- bump the version deliberately, or
- delete the existing tag in the GHCR package UI, then run the workflow
  (`Actions → build → Run workflow`).

## Local use

Edit `opencode-sandbox.ps1` and set `$ImageOwner` to your GitHub username/org
(the image owner must match the repo owner). Then:

```
cd C:\path\to\myapp
opencode-sandbox --standalone
```

The script pulls `ghcr.io/<owner>/opencode-sandbox:latest` and fails hard if the
pull does not succeed.
