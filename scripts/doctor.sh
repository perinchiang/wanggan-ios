#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

FULL=0
for arg in "$@"; do
  case "$arg" in
    --full)
      FULL=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/doctor.sh [--full]

Default mode runs quick, read-only environment checks: macOS, xcode-select,
Xcode, Swift, XcodeGen, iOS Simulator runtime, available iPhone simulator,
project scripts/resources, and test tooling. It never boots a simulator,
never modifies the system, and never installs software.

--full additionally runs the project's existing verifications in order:
  swift test
  node --test scripts/test_ipv4_visual.cjs
  swift scripts/generate_icon.swift
  xcodegen generate
  xcodebuild -project WangGan.xcodeproj -scheme WangGan -configuration Debug
    -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
No simulator is booted in --full mode either. Logs of failed steps are kept
under build/.
EOF
      exit 0
      ;;
    *)
      printf 'unknown option: %s (try --help)\n' "$arg" >&2
      exit 2
      ;;
  esac
done

if [ -t 1 ]; then
  C_PASS='\033[32m'
  C_WARN='\033[33m'
  C_FAIL='\033[31m'
  C_OFF='\033[0m'
else
  C_PASS=''
  C_WARN=''
  C_FAIL=''
  C_OFF=''
fi

PASS_N=0
WARN_N=0
FAIL_N=0

pass() {
  printf '%b[PASS]%b %s\n' "$C_PASS" "$C_OFF" "$1"
  PASS_N=$((PASS_N + 1))
}

warn() {
  printf '%b[WARN]%b %s\n' "$C_WARN" "$C_OFF" "$1"
  if [ -n "${2:-}" ]; then
    printf '       note: %s\n' "$2"
  fi
  WARN_N=$((WARN_N + 1))
}

fail() {
  printf '%b[FAIL]%b %s\n' "$C_FAIL" "$C_OFF" "$1"
  if [ -n "${2:-}" ]; then
    printf '       next: %s\n' "$2"
  fi
  FAIL_N=$((FAIL_N + 1))
}

section() {
  printf '\n%s\n' "$1"
}

printf 'WangGan doctor\n'
printf 'project: %s\n' "$ROOT_DIR"

section 'System'
OS_NAME="$(uname -s 2>/dev/null || echo unknown)"
if [ "$OS_NAME" = 'Darwin' ]; then
  pass "macOS $(uname -sr 2>/dev/null || true)"
else
  fail "macOS required, detected: $OS_NAME" 'run this script on the Mac used for iOS development; on Windows use the GitHub Actions workflow instead (see README)'
fi

section 'Xcode toolchain'
DEV_DIR="$(xcode-select -p 2>/dev/null || true)"
if [ -z "$DEV_DIR" ]; then
  fail 'xcode-select: no developer directory set' 'install Xcode, then run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'
else
  case "$DEV_DIR" in
    *CommandLineTools*)
      fail "xcode-select: $DEV_DIR points at Command Line Tools, not Xcode" 'run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'
      ;;
    *)
      if [ -d "$DEV_DIR" ]; then
        pass "xcode-select: $DEV_DIR"
      else
        fail "xcode-select: developer directory does not exist: $DEV_DIR" 'run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'
      fi
      ;;
  esac
fi

if command -v xcodebuild >/dev/null 2>&1; then
  XCODE_VER="$(xcodebuild -version 2>/dev/null | sed -n '1p')"
  XCODE_MAJOR="$(printf '%s\n' "$XCODE_VER" | sed -n 's/^Xcode \([0-9][0-9]*\).*/\1/p')"
  if [ -z "$XCODE_VER" ]; then
    fail 'Xcode: xcodebuild did not report a version' 'open /Applications/Xcode once and run: sudo xcodebuild -license accept'
  elif [ -z "$XCODE_MAJOR" ]; then
    warn "Xcode: unexpected output: $XCODE_VER"
  elif [ "$XCODE_MAJOR" -ge 16 ]; then
    pass "Xcode: $XCODE_VER"
  else
    warn "Xcode: $XCODE_VER (project.yml declares xcodeVersion 16.0)" 'install Xcode 16 or newer if xcodegen or the build fails'
  fi
else
  fail 'Xcode: xcodebuild not found' 'install Xcode from the App Store, then run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'
fi

if command -v swift >/dev/null 2>&1; then
  SWIFT_VER="$(swift --version 2>/dev/null | sed -n '1p')"
  if [ -n "$SWIFT_VER" ]; then
    pass "Swift: $SWIFT_VER"
  else
    fail "Swift: 'swift' exists but --version printed nothing" 'run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'
  fi
else
  fail 'Swift: not found' 'install Xcode, which ships the Swift toolchain'
fi

if command -v xcodegen >/dev/null 2>&1; then
  XCODEGEN_VER="$(xcodegen --version 2>/dev/null | sed -n '1p')"
  pass "XcodeGen: ${XCODEGEN_VER:-installed}"
else
  fail 'XcodeGen: not installed' 'run: brew install xcodegen'
fi

section 'iOS Simulator'
if ! command -v xcrun >/dev/null 2>&1; then
  fail 'xcrun: not found' 'install Xcode, then run: sudo xcodebuild -license accept'
else
  RUNTIMES="$(xcrun simctl list runtimes 2>/dev/null | grep -E '^iOS ' | grep -Ev 'unavailable' || true)"
  if [ -n "$RUNTIMES" ]; then
    pass "iOS Simulator runtime: $(printf '%s\n' "$RUNTIMES" | sed -n '1s/ (.*//p') available"
  else
    fail 'iOS Simulator runtime: none installed' 'install one in Xcode → Settings → Platforms, or run: xcodebuild -downloadPlatform iOS'
  fi

  PHONES="$(xcrun simctl list devices available 2>/dev/null | grep -E '^[[:space:]]+iPhone ' || true)"
  if [ -n "$PHONES" ]; then
    PHONE_COUNT="$(printf '%s\n' "$PHONES" | wc -l | tr -d ' ')"
    PHONE_SAMPLE="$(printf '%s\n' "$PHONES" | sed -n '1s/^[[:space:]]*//p' | sed 's/ (.*//')"
    pass "iPhone Simulator: $PHONE_COUNT available (e.g. $PHONE_SAMPLE)"
  else
    fail 'iPhone Simulator: none available' 'install an iOS runtime (Xcode → Settings → Platforms) and accept the license: sudo xcodebuild -license accept'
  fi
fi

section 'Project scripts and resources'
REQUIRED_PATHS='project.yml
Package.swift
Resources/lessons.json
Resources/ipv4-address-visual.html
scripts/generate_icon.swift
scripts/test_ipv4_visual.cjs
scripts/select_simulator.py
scripts/prepare_simulator_webkit.py
scripts/run_command_with_timeout.py
Sources/Core
Sources/App
Tests/CoreTests
Tests/UITests'
MISSING_PATHS=''
PATH_COUNT=0
for path in $REQUIRED_PATHS; do
  PATH_COUNT=$((PATH_COUNT + 1))
  if [ ! -e "$path" ]; then
    MISSING_PATHS="$MISSING_PATHS $path"
  fi
done
if [ -z "$MISSING_PATHS" ]; then
  pass "project scripts and resources: $PATH_COUNT paths present"
else
  fail "project scripts and resources: missing:$MISSING_PATHS" 'restore them with: git checkout -- <path>, or re-clone the repository'
fi

section 'Test tooling'
if command -v node >/dev/null 2>&1; then
  pass "Node: $(node --version 2>/dev/null)"
else
  warn 'Node: not found' 'needed for the Web tests (node --test scripts/test_ipv4_visual.cjs), including the --full run and CI'
fi
if command -v python3 >/dev/null 2>&1; then
  pass "python3: $(python3 --version 2>&1 | sed -n 's/^Python //p')"
else
  warn 'python3: not found' 'needed by the CI simulator helper scripts under scripts/'
fi

if [ "$FULL" = '1' ]; then
  section 'Full verification (--full)'
  if [ "$FAIL_N" -gt 0 ]; then
    fail '--full: skipped because environment checks failed' 'fix the [FAIL] items above, then re-run: ./scripts/doctor.sh --full'
  else
    mkdir -p build 2>/dev/null || true
    STEP_N=0
    run_step() {
      STEP_LABEL="$1"
      shift
      STEP_N=$((STEP_N + 1))
      STEP_LOG="build/doctor-step-$STEP_N.log"
      printf '\n$ %s\n' "$*"
      if "$@" >"$STEP_LOG" 2>&1; then
        pass "$STEP_LABEL"
        rm -f "$STEP_LOG"
      else
        fail "$STEP_LABEL" "log kept at $STEP_LOG; tail below"
        printf '%s\n' '--- log tail ---'
        tail -n 40 "$STEP_LOG"
        printf '%s\n' '-----------------'
      fi
    }

    run_step 'Core tests: swift test' swift test
    if command -v node >/dev/null 2>&1; then
      run_step 'Web tests: node --test scripts/test_ipv4_visual.cjs' node --test scripts/test_ipv4_visual.cjs
    else
      fail 'Web tests: skipped because node is not installed' 'install Node.js, then re-run: ./scripts/doctor.sh --full'
    fi
    run_step 'Icon generation: swift scripts/generate_icon.swift' swift scripts/generate_icon.swift
    run_step 'Xcode project: xcodegen generate' xcodegen generate
    run_step 'Compile: generic iOS Simulator' xcodebuild -project WangGan.xcodeproj -scheme WangGan -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath build/doctor CODE_SIGNING_ALLOWED=NO build
  fi
fi

printf '\nSummary: %d passed, %d warnings, %d failed\n' "$PASS_N" "$WARN_N" "$FAIL_N"
if [ "$FAIL_N" -gt 0 ]; then
  printf '%bResult: FAIL%b — follow the "next:" hints above, then re-run ./scripts/doctor.sh\n' "$C_FAIL" "$C_OFF"
  exit 1
fi
if [ "$WARN_N" -gt 0 ]; then
  printf '%bResult: OK with warnings%b\n' "$C_WARN" "$C_OFF"
else
  printf '%bResult: OK%b\n' "$C_PASS" "$C_OFF"
fi
exit 0
