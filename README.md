# Homebrew tap

```sh
brew install --cask sebastian-suarez/tap/ai-usage
```

Casks for [sebastian-suarez](https://github.com/sebastian-suarez)'s apps.

## Updating a cask

Bump `version` and `sha256`, then push. CI refuses the change unless the tag is
a **published** GitHub release (drafts are not downloadable) and the asset it
points at hashes to the cask's `sha256`, so a stale or mistyped hash can never
reach `main` and break `brew install`. Run `scripts/verify-cask.sh` locally to
check before pushing.
