#!/usr/bin/env bash
# Publish the wiki/ pages to the GitHub wiki.
#
# GitHub only creates the wiki git repo AFTER the wiki is initialised: go to
#   https://github.com/ebareke/ultimadRNAseq/wiki  →  "Create the first page"
#   (save anything), then run this script. It mirrors wiki/*.md to the wiki repo.
set -euo pipefail

REPO_SSH="${WIKI_REPO:-git@github.com:ebareke/ultimadRNAseq.wiki.git}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone "$REPO_SSH" "$TMP"
# copy pages (skip this script)
find "$HERE" -maxdepth 1 -name '*.md' -exec cp {} "$TMP"/ \;

cd "$TMP"
git add -A
if git diff --cached --quiet; then
    echo "Wiki already up to date."
else
    git commit -m "Update wiki from repo wiki/"
    git push origin HEAD
    echo "Wiki published: https://github.com/ebareke/ultimadRNAseq/wiki"
fi
