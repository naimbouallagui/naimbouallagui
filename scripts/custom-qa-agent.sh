#!/usr/bin/env bash
set -euo pipefail

TARGET_BRANCH="${1:-}"
DEPLOY_FLAG="${2:-}"
CONFIG_FILE="${QA_AGENT_CONFIG:-.qa-agent.conf}"

if [[ -z "$TARGET_BRANCH" ]]; then
  echo "Usage: ./scripts/custom-qa-agent.sh <target-branch> [--deploy]"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE"
  echo "Copy .qa-agent.conf.example to .qa-agent.conf and update it."
  exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
TMP_DIR="$(mktemp -d /tmp/custom-qa-agent-XXXXXX)"

cleanup() {
  git worktree remove -f "$TMP_DIR" >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

run_step() {
  local step_name="$1"
  local command="$2"

  if [[ -z "$command" ]]; then
    echo "Skipping $step_name (no command configured)."
    return
  fi

  echo "==> $step_name"
  bash -lc "$command"
}

echo "==> Syncing target branch: $TARGET_BRANCH"
git fetch origin "$TARGET_BRANCH"

echo "==> Running quality checks on branch: $CURRENT_BRANCH"
run_step "Lint checks" "${LINT_COMMAND:-}"
run_step "Tests" "${TEST_COMMAND:-}"
run_step "Modern review checks" "${REVIEW_COMMAND:-}"

echo "==> Simulating merge with origin/$TARGET_BRANCH to detect conflicts/regressions"
git worktree add -f "$TMP_DIR" "$CURRENT_BRANCH" >/dev/null

pushd "$TMP_DIR" >/dev/null
if ! git merge --no-commit --no-ff "origin/$TARGET_BRANCH"; then
  echo "Merge conflict detected while merging origin/$TARGET_BRANCH into $CURRENT_BRANCH."
  exit 2
fi

run_step "Post-merge regression checks" "${REGRESSION_TEST_COMMAND:-${TEST_COMMAND:-}}"
git merge --abort >/dev/null 2>&1 || true
popd >/dev/null

if [[ "$DEPLOY_FLAG" == "--deploy" ]]; then
  run_step "Deploy" "${DEPLOY_COMMAND:-}"
fi

echo "✅ Custom QA agent completed successfully."
