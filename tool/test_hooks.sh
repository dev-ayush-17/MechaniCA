#!/bin/sh
# Smoke-tests the git hooks. Run from the repo root: sh tool/test_hooks.sh
set -u
fail=0
msg=$(mktemp)

check_msg() { # expected_exit subject
  printf '%s\n' "$2" > "$msg"
  sh .githooks/commit-msg "$msg" >/dev/null 2>&1
  code=$?
  if [ "$code" -ne "$1" ]; then echo "FAIL commit-msg: '$2' exited $code"; fail=1; fi
}

check_msg 0 "feat(auth): add phone sign-in"
check_msg 0 "chore: tidy"
check_msg 1 "Added stuff"
check_msg 1 "feat add thing"
check_msg 1 "feat(auth): $(printf 'x%.0s' $(seq 1 80))"

zero=0000000000000000000000000000000000000000
head_sha=$(git rev-parse HEAD)

check_push() { # expected_exit remote_ref local_sha remote_sha
  printf 'refs/heads/x %s %s %s\n' "$3" "$2" "$4" | sh .githooks/pre-push >/dev/null 2>&1
  code=$?
  if [ "$code" -ne "$1" ]; then echo "FAIL pre-push: $2 exited $code"; fail=1; fi
}

check_push 1 refs/heads/main "$head_sha" "$zero"
check_push 0 refs/heads/feat/x "$head_sha" "$zero"
check_push 1 refs/heads/feat/x "$zero" "$head_sha"
# remote tip that is not an ancestor of local = force push
first_sha=$(git rev-list --max-parents=0 HEAD | head -n 1)
check_push 0 refs/heads/feat/x "$head_sha" "$first_sha"
check_push 1 refs/heads/feat/x "$first_sha" "$head_sha"

rm -f "$msg"
if [ "$fail" -eq 0 ]; then echo "Hooks OK."; fi
exit "$fail"
