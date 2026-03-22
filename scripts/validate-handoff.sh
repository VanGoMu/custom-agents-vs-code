#!/usr/bin/env bash
# scripts/validate-handoff.sh — Verify that an installed handoff is correctly configured.
#
# Usage:
#   ./scripts/validate-handoff.sh --handoff <name> [--repo | --profile]
#
# Output:
#   ✓ All checks passed — handoff is ready to use
#   ✗ Checks failed — lists specific issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO_DEST=".github/agents"
PROFILE_DEST="$HOME/.github/agents"

HANDOFF_NAME=""
SCOPE="repo"
DEST=""
ORCHESTRATOR_FILE=""
HANDOFF_DIR=""
ERRORS=()
WARNINGS=()
PASSED=0
TOTAL_CHECKS=0

die() { echo "Error: $*" >&2; exit 1; }
warn() { echo "Warning: $*" >&2; }
info() { echo "$*"; }

usage() {
  local exit_code="${1:-1}"
  cat >&2 <<EOF
Usage:
  $(basename "$0") --handoff <name> [--repo | --profile]

Options:
  --handoff <name>  Name of the installed handoff to validate
  --repo            Validate in repo scope (.github/agents/)
  --profile         Validate in user profile scope (~/.github/agents/)
  --help            Show this help
EOF
  exit "$exit_code"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --handoff)
        [[ -z "${2:-}" ]] && die "--handoff requires a name"
        HANDOFF_NAME="$2"
        shift 2
        ;;
      --repo)
        SCOPE="repo"
        shift
        ;;
      --profile)
        SCOPE="profile"
        shift
        ;;
      --help|-h)
        usage 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done

  [[ -n "$HANDOFF_NAME" ]] || die "--handoff is required"
}

resolve_paths() {
  if [[ "$SCOPE" == "repo" ]]; then
    DEST="$REPO_ROOT/$REPO_DEST"
  else
    DEST="$PROFILE_DEST"
  fi

  ORCHESTRATOR_FILE="$DEST/${HANDOFF_NAME}.agent.md"
  HANDOFF_DIR="$DEST/$HANDOFF_NAME"
}

check_orchestrator_exists() {
  ((TOTAL_CHECKS++))
  
  if [[ -f "$ORCHESTRATOR_FILE" ]]; then
    info "  ✓ Orchestrator exists: $(basename "$ORCHESTRATOR_FILE")"
    ((PASSED++))
    return 0
  else
    ERRORS+=("Orchestrator not found: $ORCHESTRATOR_FILE")
    return 1
  fi
}

check_orchestrator_valid() {
  ((TOTAL_CHECKS++))
  
  if [[ ! -f "$ORCHESTRATOR_FILE" ]]; then
    return 1
  fi

  local required_fields=("name:" "description:" "tools:")
  local field
  local missing=()
  
  for field in "${required_fields[@]}"; do
    if ! grep -q "^$field" "$ORCHESTRATOR_FILE"; then
      missing+=("$field")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    info "  ✓ Orchestrator has all required YAML fields"
    ((PASSED++))
    return 0
  else
    ERRORS+=("Orchestrator missing fields: ${missing[*]}")
    return 1
  fi
}

check_orchestrator_agents() {
  ((TOTAL_CHECKS++))
  
  if [[ ! -f "$ORCHESTRATOR_FILE" ]]; then
    return 1
  fi

  local agents_section
  agents_section=$(awk '/^agents:/{found=1; next} found && /^[^[:space:]]/{exit} found{print}' "$ORCHESTRATOR_FILE")
  
  if [[ -n "$agents_section" ]]; then
    info "  ✓ Orchestrator defines sub-agents"
    ((PASSED++))
    return 0
  else
    WARNINGS+=("Orchestrator does not define any sub-agents")
    return 0
  fi
}

check_handoff_dir_exists() {
  ((TOTAL_CHECKS++))
  
  if [[ -d "$HANDOFF_DIR" ]]; then
    info "  ✓ Handoff directory exists: $HANDOFF_DIR"
    ((PASSED++))
    return 0
  else
    WARNINGS+=("Handoff directory not found: $HANDOFF_DIR (may contain only orchestrator)")
    return 0
  fi
}

check_sub_agents() {
  ((TOTAL_CHECKS++))
  
  if [[ ! -d "$HANDOFF_DIR" ]]; then
    return 0
  fi

  local sub_agent_count
  sub_agent_count=$(find "$HANDOFF_DIR" -maxdepth 1 -type f -name '*.agent.md' 2>/dev/null | wc -l)
  
  if [[ $sub_agent_count -gt 0 ]]; then
    info "  ✓ Found $sub_agent_count sub-agent(s) in $HANDOFF_DIR"
    ((PASSED++))
    return 0
  else
    WARNINGS+=("No sub-agents found in handoff directory")
    return 0
  fi
}

check_installation_record() {
  ((TOTAL_CHECKS++))
  
  local record_file="$DEST/.installed_${HANDOFF_NAME}"
  
  if [[ -f "$record_file" ]]; then
    local ts_recorded timestamp_clean
    ts_recorded=$(grep '^TIMESTAMP=' "$record_file" 2>/dev/null | cut -d= -f2)
    if [[ -n "$ts_recorded" ]]; then
      info "  ✓ Installation record found: $record_file (installed: $ts_recorded)"
      ((PASSED++))
      return 0
    fi
  fi
  
  WARNINGS+=("No installation record found (run install.sh to create one)")
  return 0
}

check_no_cycles() {
  ((TOTAL_CHECKS++))
  
  if [[ ! -f "$ORCHESTRATOR_FILE" ]]; then
    return 1
  fi

  local agents_section
  agents_section=$(awk '/^agents:/{found=1; next} found && /^[^[:space:]]/{exit} found{print}' "$ORCHESTRATOR_FILE")
  
  if echo "$agents_section" | grep -q "$HANDOFF_NAME"; then
    ERRORS+=("Cycle detected: orchestrator references itself as a sub-agent")
    return 1
  else
    info "  ✓ No cycles detected"
    ((PASSED++))
    return 0
  fi
}

show_summary() {
  echo ""
  
  if [[ ${#ERRORS[@]} -eq 0 ]] && [[ ${#WARNINGS[@]} -eq 0 ]]; then
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  ✓ VALIDATION PASSED                           ║"
    echo "║                                                                ║"
    echo "║  Handoff '$HANDOFF_NAME' is correctly installed and ready     ║"
    echo "║  to use. You can now run:                                      ║"
    echo "║                                                                ║"
    echo "║    ./scripts/run-handoff.sh --handoff $HANDOFF_NAME \\           ║"
    echo "║      --repo --prompt \"<your prompt>\"                         ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    return 0
  fi

  echo "╔════════════════════════════════════════════════════════════════╗"
  
  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "║                  ✗ VALIDATION FAILED                          ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║  ERRORS:                                                       ║"
    for err in "${ERRORS[@]}"; do
      echo "║    • $err"
    done
  fi

  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
      echo "║                                                                ║"
    fi
    echo "║  WARNINGS:                                                     ║"
    for warning in "${WARNINGS[@]}"; do
      echo "║    • $warning"
    done
  fi

  echo "║                                                                ║"
  echo "║  Checks: $PASSED of $TOTAL_CHECKS passed                              "
  echo "╚════════════════════════════════════════════════════════════════╝"

  if [[ ${#ERRORS[@]} -gt 0 ]]; then
    return 1
  fi
  return 0
}

main() {
  parse_args "$@"
  resolve_paths

  echo ""
  echo "Validating handoff '$HANDOFF_NAME' in $SCOPE scope..."
  echo "  Destination: $DEST"
  echo ""

  check_orchestrator_exists || true
  check_orchestrator_valid || true
  check_orchestrator_agents || true
  check_handoff_dir_exists || true
  check_sub_agents || true
  check_installation_record || true
  check_no_cycles || true

  show_summary
}

main "$@"
