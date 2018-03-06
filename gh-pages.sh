#!/bin/bash
# Copyright © 2018 Martin Ueding <dev@martin-ueding.de>

set -e
set -u

# Create the `gh-pages` branch if needed.
if ! git branch | grep gh-pages; then
  old_branch=$(git rev-parse --abbrev-ref HEAD)
  git checkout --orphan gh-pages
  git reset
  git commit --allow-empty -m "Initial pages branch"
  git checkout -f "$old_branch"
fi

# Check out working directory.
workdir="$(mktemp -d)"
git worktree add "$workdir" gh-pages

# Build documentation in current branch.
doxygen

output_dir_line="$(grep -P '^OUTPUT_DIRECTORY' Doxyfile)"
output_dir="${output_dir_line#OUTPUT_DIRECTORY *= \"}"
output_dir="${output_dir%\"}"

rsync -avhE "$output_dir/html/" "$workdir/"

pushd "$workdir"
git add .
git commit -m 'New documentation'
popd

rm -rf "$workdir"
git worktree prune
