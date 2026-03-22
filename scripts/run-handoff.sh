#!/usr/bin/env bash
# scripts/run-handoff.sh — Run an installed handoff orchestrator with context accumulation.
#
# Usage:
#   ./scripts/run-handoff.sh --handoff <name> [--repo | --profile] --prompt <user_prompt> [--context-dir <path>]
#
# Examples:
#   ./scripts/run-handoff.sh --handoff shell --repo --prompt "Create a backup utility"
#   ./scripts/run-handoff.sh --handoff shell --profile --prompt "..." --context-dir /tmp/shell_context

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO_DEST=".github/agents"
PROFILE_DEST="$HOME/.github/agents"

HANDOFF_NAME=""
SCOPE=""
USER_PROMPT=""
CONTEXT_DIR=""
DEST=""
ORCHESTRATOR_FILE=""

die() { echo "Error: $*" >&2; exit 1; }
warn() { echo "Warning: $*" >&2; }
info() { echo "$*"; }

usage() {
  local exit_code="${1:-1}"
  cat >&2 <<EOF
Usage:
  $(basename "$0") --handoff <name> [--repo | --profile] --prompt <prompt> [--context-dir <path>]

Options:
  --handoff <name>      Name of the installed handoff orchestrator
  --repo                Use handoff from repo (.github/agents/)
  --profile             Use handoff from user profile (~/.github/agents/)
  --prompt <prompt>     User prompt to feed to the orchestrator
  --context-dir <path>  Directory to store context artifacts (default: /tmp)
  --help                Show this help

Notes:
  --repo and --profile are mutually exclusive (--repo is default).
  This script uses the runSubagent tool to invoke the orchestrator.
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
        [[ -n "$SCOPE" ]] && die "--repo and --profile are mutually exclusive"
        SCOPE="repo"
        shift
        ;;
      --profile)
        [[ -n "$SCOPE" ]] && die "--repo and --profile are mutually exclusive"
        SCOPE="profile"
        shift
        ;;
      --prompt)
        [[ -z "${2:-}" ]] && die "--prompt requires text"
        USER_PROMPT="$2"
        shift 2
        ;;
      --context-dir)
        [[ -z "${2:-}" ]] && die "--context-dir requires a path"
        CONTEXT_DIR="$2"
        shift 2
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
  [[ -n "$USER_PROMPT" ]] || die "--prompt is required"
  [[ -z "$SCOPE" ]] && SCOPE="repo"
  [[ -z "$CONTEXT_DIR" ]] && CONTEXT_DIR="/tmp"
}

resolve_orchestrator() {
  if [[ "$SCOPE" == "repo" ]]; then
    DEST="$REPO_ROOT/$REPO_DEST"
  else
    DEST="$PROFILE_DEST"
  fi

  ORCHESTRATOR_FILE="$DEST/${HANDOFF_NAME}.agent.md"
  
  if [[ ! -f "$ORCHESTRATOR_FILE" ]]; then
    die "Orchestrator not found: $ORCHESTRATOR_FILE (did you run 'install.sh --handoff $HANDOFF_NAME'?)"
  fi

  info "Found orchestrator: $ORCHESTRATOR_FILE"
}

setup_context_dir() {
  local timestamp
  timestamp="$(date +%s)"
  CONTEXT_DIR="$CONTEXT_DIR/${HANDOFF_NAME}_${timestamp}"
  mkdir -p "$CONTEXT_DIR"
  info "Context directory: $CONTEXT_DIR"
}

validate_orchestrator() {
  if ! grep -q "name:" "$ORCHESTRATOR_FILE"; then
    die "Orchestrator is malformed: missing 'name:' field"
  fi
  
  if ! grep -q "description:" "$ORCHESTRATOR_FILE"; then
    die "Orchestrator is malformed: missing 'description:' field"
  fi
  
  info "✓ Orchestrator is valid"
}

show_header() {
  cat <<EOF

╔════════════════════════════════════════════════════════════════════════════╗
║                     HANDOFF ORCHESTRATOR EXECUTION                         ║
║                                                                            ║
║  Handoff: $HANDOFF_NAME
║  Scope:   $SCOPE
║  Context: $CONTEXT_DIR
╚════════════════════════════════════════════════════════════════════════════╝

Executing handoff pipeline. Follow the agOkrchestrator instructions below:

EOF
}

show_instructions() {
  cat <<EOF

╭─────────────────────────────────────────────────────────────────────────────╮
│ NEXT STEP: Use the runSubagent tool to execute the orchestrator             │
│                                                                             │
│  runSubagent(agentName="$(basename "$ORCHESTRATOR_FILE" .agent.md)", prompt="...")
│                                                                             │
│ Handoff expects the orchestrator to:                                       │
│  1. Parse the user prompt                                                  │
│  2. Invoke sub-agents sequentially (PromptValidator → ...Developers...)    │
│  3. Accumulate context between steps ([ESTRUCTURA], [TESTS], [SCRIPTS])   │
│  4. Return final artifacts                                                 │
│                                                                             │
│ Context Files (populate as orchestrator progresses):                       │
│  • $CONTEXT_DIR/ESTRUCTURA.md        (Step 2 output)
│  • $CONTEXT_DIR/TESTS.md             (Step 3 output)
│  • $CONTEXT_DIR/SCRIPTS.md           (Step 4 output)
│  • $CONTEXT_DIR/DEVOPS.md            (Step 5 output)
│                                                                             │
│ To run manually:                                                           │
│  cd $(dirname "$ORCHESTRATOR_FILE")
│  # Invoke the orchestrator with the user prompt                            │
╰─────────────────────────────────────────────────────────────────────────────╯

EOF
}

main() {
  parse_args "$@"
  resolve_orchestrator
  validate_orchestrator
  setup_context_dir
  show_header
  
  info "User prompt: $USER_PROMPT"
  info ""
  
  show_instructions
  
  info "To complete the handoff, you must invoke the orchestrator using runSubagent."
  info "The orchestrator is located at: $ORCHESTRATOR_FILE"
  info ""
  info "Ready to proceed. Use the runSubagent tool with the prompt above."
}

main "$@"
