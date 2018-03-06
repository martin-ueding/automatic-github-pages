#!/bin/bash
# Copyright © 2018 Martin Ueding <dev@martin-ueding.de>

set -e
set -u
  old_branch=$(git rev-parse --abbrev-ref HEAD)
set -x

repo_dir="$(pwd)"
old_branch=$(git rev-parse --abbrev-ref HEAD)

# Create the `gh-pages` branch if needed.
if ! git branch | grep gh-pages; then
  git checkout --orphan gh-pages
  git reset
  git commit --allow-empty -m "Initial pages branch"
  git checkout -f "$old_branch"
fi

git pull origin "$old_branch"

workdir="$(mktemp -d)"

cleanup() {
    rm -rf "$workdir"
    cd "$repo_dir"
    git worktree prune
}

trap cleanup EXIT

# Check out working directory.
git worktree add "$workdir" gh-pages

pushd "$workdir"
git pull origin gh-pages
popd

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
