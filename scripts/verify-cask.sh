#!/usr/bin/env bash
# Verify that every cask points at a published GitHub release whose asset
# hashes to the cask's sha256. Guards the manual bump-and-push flow: a cask
# that references a draft, a missing asset, or a stale sha256 breaks
# `brew install` for everyone, so it must never reach main.
set -euo pipefail

status=0
for cask in Casks/*.rb; do
  name="$(basename "$cask" .rb)"
  version="$(sed -nE 's/^[[:space:]]*version "([^"]+)".*/\1/p' "$cask" | head -1)"
  sha256="$(sed -nE 's/^[[:space:]]*sha256 "([^"]+)".*/\1/p' "$cask" | head -1)"
  url_template="$(sed -nE 's/^[[:space:]]*url "([^"]+)".*/\1/p' "$cask" | head -1)"
  if [[ -z "$version" || -z "$sha256" || -z "$url_template" ]]; then
    echo "::error file=$cask::could not read version, sha256 and url from the cask"
    status=1; continue
  fi
  url="${url_template//\#\{version\}/$version}"

  # https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>
  if [[ "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)$ ]]; then
    repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"; tag="${BASH_REMATCH[3]}"; asset="${BASH_REMATCH[4]}"
  else
    echo "::error file=$cask::url is not a GitHub release asset: $url"
    status=1; continue
  fi

  echo "$name $version → $repo $tag $asset"

  if ! release="$(gh release view "$tag" --repo "$repo" --json isDraft,assets 2>/dev/null)"; then
    echo "::error file=$cask::release $tag does not exist in $repo; publish it before bumping the cask"
    status=1; continue
  fi
  if [[ "$(jq -r .isDraft <<<"$release")" == "true" ]]; then
    echo "::error file=$cask::release $tag in $repo is still a draft; its assets are not downloadable. Publish it first."
    status=1; continue
  fi
  if ! jq -e --arg a "$asset" '.assets[] | select(.name == $a)' <<<"$release" >/dev/null; then
    echo "::error file=$cask::release $tag in $repo has no asset named $asset"
    status=1; continue
  fi

  tmp="$(mktemp)"
  curl -fsSL --retry 3 -o "$tmp" "$url"
  actual="$(shasum -a 256 "$tmp" | cut -d' ' -f1)"
  rm -f "$tmp"
  if [[ "$actual" != "$sha256" ]]; then
    echo "::error file=$cask::sha256 mismatch for $asset: cask has $sha256, release asset is $actual"
    status=1; continue
  fi
  echo "ok: $name $version sha256 matches $repo $tag"
done
exit "$status"
