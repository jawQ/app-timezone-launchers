#!/usr/bin/env bash
# Self-test for WSL/Linux-side helpers (runs on macOS or Linux CI too).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/wsl/bin"
PASS=0
FAIL=0
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/atl-wsl-test-XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "OK  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL $label (expected=$expected actual=$actual)" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_exit() {
  local label="$1" expected="$2"
  shift 2
  set +e
  "$@" >"$TMP_ROOT/command.out" 2>"$TMP_ROOT/command.err"
  local code=$?
  set -e
  assert_eq "$label" "$expected" "$code"
}

assert_file_line() {
  local label="$1" file="$2" line="$3"
  if grep -Fqx -- "$line" "$file"; then
    echo "OK  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL $label (missing line: $line)" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_file_no_line() {
  local label="$1" file="$2" line="$3"
  if grep -Fqx -- "$line" "$file"; then
    echo "FAIL $label (unexpected line: $line)" >&2
    FAIL=$((FAIL + 1))
  else
    echo "OK  $label"
    PASS=$((PASS + 1))
  fi
}

assert_file_contains() {
  local label="$1" file="$2" text="$3"
  if grep -Fq -- "$text" "$file"; then
    echo "OK  $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL $label (missing text: $text)" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert_file_not_contains() {
  local label="$1" file="$2" text="$3"
  if grep -Fq -- "$text" "$file"; then
    echo "FAIL $label (unexpected text: $text)" >&2
    FAIL=$((FAIL + 1))
  else
    echo "OK  $label"
    PASS=$((PASS + 1))
  fi
}

# run-with-tz injects TZ for a child process
out="$( "$BIN/run-with-tz" Asia/Tokyo printenv TZ )"
assert_eq "run-with-tz sets TZ" "Asia/Tokyo" "$out"

out="$( RUN_TZ=Europe/Berlin "$BIN/run-with-tz" -- printenv TZ )"
assert_eq "run-with-tz RUN_TZ + --" "Europe/Berlin" "$out"

out="$( RUN_TZ=Europe/Berlin "$BIN/run-with-tz" Asia/Tokyo printenv TZ )"
assert_eq "run-with-tz explicit TZ overrides RUN_TZ" "Asia/Tokyo" "$out"

# RUN_TZ without --: non-IANA first arg is the command (not a TZ).
out="$( RUN_TZ=Asia/Shanghai "$BIN/run-with-tz" printenv TZ )"
assert_eq "run-with-tz RUN_TZ without --" "Asia/Shanghai" "$out"

out="$( RUN_TZ=Europe/Berlin "$BIN/run-with-tz" UTC printenv TZ )"
assert_eq "run-with-tz UTC token overrides RUN_TZ" "UTC" "$out"

assert_exit "run-with-tz missing command" 1 "$BIN/run-with-tz" Asia/Shanghai
assert_exit "run-with-tz help" 0 "$BIN/run-with-tz" --help
assert_exit "run-with-tz RUN_TZ alone missing command" 1 env RUN_TZ=Asia/Shanghai "$BIN/run-with-tz"

# docker-tz only treats a real TZ env option as an existing container TZ.
FAKE_DOCKER="$TMP_ROOT/docker"
cat >"$FAKE_DOCKER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$DOCKER_ARGS_FILE"
EOF
chmod +x "$FAKE_DOCKER"

DOCKER_ARGS_FILE="$TMP_ROOT/docker.args"
export DOCKER_ARGS_FILE

DOCKER_BIN="$FAKE_DOCKER" DOCKER_INJECT_TZ=1 DOCKER_TZ=Asia/Tokyo \
  "$BIN/docker-tz" run --rm -e APP_TZ=UTC alpine env >/dev/null
assert_file_line "docker-tz injects TZ beside unrelated APP_TZ" "$DOCKER_ARGS_FILE" "TZ=Asia/Tokyo"

DOCKER_BIN="$FAKE_DOCKER" DOCKER_INJECT_TZ=1 DOCKER_TZ=Asia/Tokyo \
  "$BIN/docker-tz" run --rm -e OTHER=TZ=UTC alpine env >/dev/null
assert_file_line "docker-tz ignores TZ text in another env value" "$DOCKER_ARGS_FILE" "TZ=Asia/Tokyo"

DOCKER_BIN="$FAKE_DOCKER" DOCKER_INJECT_TZ=1 DOCKER_TZ=Asia/Tokyo \
  "$BIN/docker-tz" run --rm -e TZ=UTC alpine env >/dev/null
assert_file_line "docker-tz preserves explicit -e TZ" "$DOCKER_ARGS_FILE" "TZ=UTC"
assert_file_no_line "docker-tz does not duplicate explicit -e TZ" "$DOCKER_ARGS_FILE" "TZ=Asia/Tokyo"

DOCKER_BIN="$FAKE_DOCKER" DOCKER_INJECT_TZ=1 DOCKER_TZ=Asia/Tokyo \
  "$BIN/docker-tz" run --rm --env=TZ=Europe/Berlin alpine env >/dev/null
assert_file_line "docker-tz recognizes --env=TZ" "$DOCKER_ARGS_FILE" "--env=TZ=Europe/Berlin"
assert_file_no_line "docker-tz does not duplicate --env=TZ" "$DOCKER_ARGS_FILE" "TZ=Asia/Tokyo"

# Default install output uses the selected prefix and does not advertise wrappers
# that were not installed.
DEFAULT_PREFIX="$TMP_ROOT/default-prefix"
DEFAULT_OUTPUT="$TMP_ROOT/default-install.out"
"$ROOT/wsl/install.sh" --prefix "$DEFAULT_PREFIX" >"$DEFAULT_OUTPUT"
test -x "$DEFAULT_PREFIX/run-with-tz"
test -x "$DEFAULT_PREFIX/code-tz"
test -x "$DEFAULT_PREFIX/docker-tz"
assert_file_contains "install PATH export uses custom prefix" "$DEFAULT_OUTPUT" \
  "export PATH=${DEFAULT_PREFIX}:\"\$PATH\""
assert_file_not_contains "default install omits Feishu example" "$DEFAULT_OUTPUT" "feishu-tz"
assert_file_not_contains "default install omits WeChat example" "$DEFAULT_OUTPUT" "wechat-tz"

# --all installs and advertises both Windows interop wrappers.
ALL_PREFIX="$TMP_ROOT/all-prefix"
ALL_OUTPUT="$TMP_ROOT/all-install.out"
"$ROOT/wsl/install.sh" --all --prefix "$ALL_PREFIX" >"$ALL_OUTPUT"
test -x "$ALL_PREFIX/feishu-tz"
test -x "$ALL_PREFIX/wechat-tz"
test -f "$ALL_PREFIX/feishu-tz.ps1"
test -f "$ALL_PREFIX/wechat-tz.ps1"
test -f "$ALL_PREFIX/_lib.ps1"
assert_file_contains "--all output includes Feishu example" "$ALL_OUTPUT" "feishu-tz"
assert_file_contains "--all output includes WeChat example" "$ALL_OUTPUT" "wechat-tz"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
if (( FAIL > 0 )); then
  exit 1
fi
