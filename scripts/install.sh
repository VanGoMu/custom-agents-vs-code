#!/usr/bin/env bash
# scripts/install.sh — Install custom agents or handoffs to a repo workspace or user profile.
#
# Usage:
#   ./scripts/install.sh --agent <name>   [--repo | --profile] [--source <path> | --archive <path>]
#   ./scripts/install.sh --handoff <name> [--repo | --profile] [--source <path> | --archive <path>]
#
# Source options:
#   default       Uses this repository layout (agents/ and handoffs/).
#   --source      Uses a local folder as source.
#   --archive     Uses a local .zip or .tar.* archive as source.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO_DEST=".github/agents"
PROFILE_DEST="$HOME/.github/agents"

MODE=""
NAME=""
SCOPE=""
SOURCE_PATH=""
ARCHIVE_PATH=""
DEST=""

SOURCE_ROOT=""
SOURCE_AGENTS_DIR=""
SOURCE_HANDOFFS_DIR=""

TEMP_DIR=""
AGENTS_TO_COPY=()
HANDOFF_ORCHESTRATOR=""

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

usage() {
  local exit_code="${1:-1}"
  cat >&2 <<EOF
Usage:
  $(basename "$0") --agent <name>   [--repo | --profile] [--source <path> | --archive <path>]
  $(basename "$0") --handoff <name> [--repo | --profile] [--source <path> | --archive <path>]

Options:
  --agent <name>    Install a single agent by name
  --handoff <name>  Install a handoff (orchestrator + referenced sub-agents)
  --repo            Target the current repo (.github/agents/)
  --profile         Target the user profile (~/.github/agents/)
  --source <path>   Use a local folder as source instead of this repository
  --archive <path>  Use a local archive (.zip, .tar, .tar.gz, .tgz, .tar.bz2, .tbz2)
  --help            Show this help

Notes:
  --source and --archive are mutually exclusive.
EOF
  exit "$exit_code"
}

die() { echo "Error: $*" >&2; exit 1; }
warn() { echo "Warning: $*" >&2; }
info() { echo "$*"; }

list_available_agents() {
  if [[ -d "$SOURCE_AGENTS_DIR" ]]; then
    ls "$SOURCE_AGENTS_DIR"/*.agent.md 2>/dev/null | xargs -I{} basename {} .agent.md | sed 's/^/  /' || true
  else
    echo "  (none found)"
  fi
}

list_available_handoffs() {
  if [[ -d "$SOURCE_HANDOFFS_DIR" ]]; then
    ls -d "$SOURCE_HANDOFFS_DIR"/*/ 2>/dev/null | xargs -I{} basename {} | sed 's/^/  /' || true
  else
    echo "  (none found)"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent)
        [[ -n "$MODE" ]] && die "--agent and --handoff are mutually exclusive"
        [[ -z "${2:-}" ]] && die "--agent requires a name"
        MODE="agent"
        NAME="$2"
        shift 2
        ;;
      --handoff)
        [[ -n "$MODE" ]] && die "--agent and --handoff are mutually exclusive"
        [[ -z "${2:-}" ]] && die "--handoff requires a name"
        MODE="handoff"
        NAME="$2"
        shift 2
        ;;
      --repo)
        [[ "$SCOPE" == "profile" ]] && die "--repo and --profile are mutually exclusive"
        SCOPE="repo"
        shift
        ;;
      --profile)
        [[ "$SCOPE" == "repo" ]] && die "--repo and --profile are mutually exclusive"
        SCOPE="profile"
        shift
        ;;
      --source)
        [[ -n "$ARCHIVE_PATH" ]] && die "--source and --archive are mutually exclusive"
        [[ -z "${2:-}" ]] && die "--source requires a path"
        SOURCE_PATH="$2"
        shift 2
        ;;
      --archive)
        [[ -n "$SOURCE_PATH" ]] && die "--source and --archive are mutually exclusive"
        [[ -z "${2:-}" ]] && die "--archive requires a path"
        ARCHIVE_PATH="$2"
        shift 2
        ;;
      --help|-h)
        usage 0
        ;;
      *)
        usage
        ;;
    esac
  done

  if [[ -z "$MODE" ]]; then
    usage
  fi

  if [[ -z "$SCOPE" ]]; then
    die "--repo or --profile is required"
  fi

  return 0
}

resolve_dest() {
  if [[ "$SCOPE" == "repo" ]]; then
    DEST="$REPO_DEST"
  else
    DEST="$PROFILE_DEST"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

normalize_path() {
  local candidate="$1"
  if [[ -d "$candidate" || -f "$candidate" ]]; then
    echo "$(cd "$(dirname "$candidate")" && pwd)/$(basename "$candidate")"
  else
    die "Path not found: $candidate"
  fi
}

extract_archive() {
  local archive="$1"
  local lower

  require_cmd mktemp
  TEMP_DIR="$(mktemp -d)"

  lower="$(echo "$archive" | tr '[:upper:]' '[:lower:]')"

  case "$lower" in
    *.zip)
      require_cmd unzip
      unzip -q "$archive" -d "$TEMP_DIR"
      ;;
    *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2)
      require_cmd tar
      tar -xf "$archive" -C "$TEMP_DIR"
      ;;
    *)
      die "Unsupported archive format: $archive"
      ;;
  esac

  echo "$TEMP_DIR"
}

detect_layout_from_base() {
  local base="$1"
  local mode="$2"
  local candidate=""

  if [[ -d "$base/agents" && -d "$base/handoffs" ]]; then
    SOURCE_ROOT="$base"
    SOURCE_AGENTS_DIR="$base/agents"
    SOURCE_HANDOFFS_DIR="$base/handoffs"
    return 0
  fi

  while IFS= read -r candidate; do
    if [[ -d "$candidate/agents" && -d "$candidate/handoffs" ]]; then
      SOURCE_ROOT="$candidate"
      SOURCE_AGENTS_DIR="$candidate/agents"
      SOURCE_HANDOFFS_DIR="$candidate/handoffs"
      return 0
    fi
  done < <(find "$base" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | sort)

  if [[ "$mode" == "agent" && -d "$base/.github/agents" ]]; then
    SOURCE_ROOT="$base"
    SOURCE_AGENTS_DIR="$base/.github/agents"
    SOURCE_HANDOFFS_DIR=""
    return 0
  fi

  while IFS= read -r candidate; do
    if [[ "$mode" == "agent" && -d "$candidate/.github/agents" ]]; then
      SOURCE_ROOT="$candidate"
      SOURCE_AGENTS_DIR="$candidate/.github/agents"
      SOURCE_HANDOFFS_DIR=""
      return 0
    fi
  done < <(find "$base" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | sort)

  return 1
}

resolve_source_layout() {
  local base=""

  if [[ -n "$SOURCE_PATH" ]]; then
    base="$(normalize_path "$SOURCE_PATH")"
    [[ -d "$base" ]] || die "--source must point to a directory"
  elif [[ -n "$ARCHIVE_PATH" ]]; then
    local archive
    archive="$(normalize_path "$ARCHIVE_PATH")"
    [[ -f "$archive" ]] || die "--archive must point to a file"
    base="$(extract_archive "$archive")"
  else
    base="$REPO_ROOT"
  fi

  detect_layout_from_base "$base" "$MODE" || die "Could not find a valid source layout in: $base"
}

parse_agents_from_yaml() {
  local config_file="$1"
  awk '
    /^agents[[:space:]]*:[[:space:]]*$/ {in_agents=1; next}
    in_agents && /^[^[:space:]]/ {exit}
    in_agents && /^[[:space:]]+[^[:space:]]+[[:space:]]*:[[:space:]]*/ {
      sub(/^[[:space:]]+[^[:space:]]+[[:space:]]*:[[:space:]]*/, "", $0)
      gsub(/^"|"$/, "", $0)
      gsub(/^\047|\047$/, "", $0)
      print $0
      next
    }
  ' "$config_file"
}

check_destination_writable() {
  local probe_parent="$DEST"
  while [[ ! -d "$probe_parent" ]]; do
    probe_parent="$(dirname "$probe_parent")"
    [[ "$probe_parent" == "/" ]] && break
  done

  if [[ ! -w "$probe_parent" ]]; then
    die "Destination parent is not writable: $probe_parent"
  fi
}

preflight_agent() {
  local src="$SOURCE_AGENTS_DIR/${NAME}.agent.md"
  [[ -f "$src" ]] || {
    info "Available agents:"
    list_available_agents
    die "Agent file not found: $src"
  }

  AGENTS_TO_COPY=("$src")
}

parse_dependencies_from_yaml() {
  local config_file="$1"
  awk '
    /^dependencias[[:space:]]*:[[:space:]]*$/ {in_deps=1; next}
    in_deps && /^[[:space:]]*-[[:space:]]+/ {
      sub(/^[[:space:]]*-[[:space:]]+/, "", $0)
      gsub(/^"|"$/, "", $0)
      gsub(/^\047|\047$/, "", $0)
      print $0
      next
    }
    in_deps && /^[^[:space:]]/ {exit}
  ' "$config_file"
}

check_dependency() {
  local dep="$1"
  case "$dep" in
    typescript)       command -v tsc        >/dev/null 2>&1 ;;
    bats-core)        command -v bats       >/dev/null 2>&1 ;;
    pytest-cov)       python3 -c "import pytest_cov" >/dev/null 2>&1 ;;
    @*)               npm list "$dep"       >/dev/null 2>&1 ;;
    jest)             command -v jest >/dev/null 2>&1 || npx --no jest --version >/dev/null 2>&1 ;;
    *)                command -v "$dep"     >/dev/null 2>&1 ;;
  esac
}

check_handoff_dependencies() {
  local config_file="$1"
  local deps dep
  local missing=()

  deps="$(parse_dependencies_from_yaml "$config_file")"
  [[ -z "$deps" ]] && return 0

  info "Checking dependencies for handoff '$NAME'..."

  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    if check_dependency "$dep"; then
      info "  ✓ $dep"
    else
      warn "  ✗ $dep — not found"
      missing+=("$dep")
    fi
  done <<< "$deps"

  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing dependencies: ${missing[*]}. Install them before using handoff '$NAME'."
  fi

  info "All dependencies satisfied."
}

check_agent_cycles() {
  local handoff_name="$1"
  local config_file="$2"
  local parsed_agents
  local agent_name
  
  parsed_agents="$(parse_agents_from_yaml "$config_file")"
  if [[ -z "$parsed_agents" ]]; then
    return 0
  fi
  
  while IFS= read -r agent_name; do
    [[ -z "$agent_name" ]] && continue
    if [[ "$agent_name" == "$handoff_name" ]]; then
      warn "Potential cycle detected: handoff '$handoff_name' references itself via agent '$agent_name'"
    fi
  done <<< "$parsed_agents"
}

preflight_handoff() {
  local handoff_dir="$SOURCE_HANDOFFS_DIR/$NAME"
  local config_file="$handoff_dir/config.yaml"
  local orchestrator=""
  local parsed_agents=""
  local agent_name=""
  local sub_src=""

  [[ -d "$SOURCE_HANDOFFS_DIR" ]] || die "Source does not include handoffs/ directory"
  [[ -d "$handoff_dir" ]] || {
    info "Available handoffs:"
    list_available_handoffs
    die "Handoff not found: $handoff_dir"
  }
  [[ -f "$config_file" ]] || die "Missing config.yaml in: $handoff_dir"

  check_handoff_dependencies "$config_file"

  orchestrator="$(find "$handoff_dir" -maxdepth 1 -type f -name '*.agent.md' | sort | head -1)"
  [[ -n "$orchestrator" ]] || die "No orchestrator .agent.md found in: $handoff_dir"

  check_agent_cycles "$NAME" "$config_file"

  mapfile -t AGENTS_TO_COPY < <(printf '%s\n' "$orchestrator")

  parsed_agents="$(parse_agents_from_yaml "$config_file")"
  if [[ -n "$parsed_agents" ]]; then
    while IFS= read -r agent_name; do
      [[ -z "$agent_name" ]] && continue
      sub_src="$SOURCE_AGENTS_DIR/${agent_name}.agent.md"
      [[ -f "$sub_src" ]] || die "Sub-agent referenced by handoff not found: $sub_src"
      AGENTS_TO_COPY+=("$sub_src")
    done <<< "$parsed_agents"
  else
    warn "No sub-agents defined in config.yaml for handoff '$NAME'"
  fi

  HANDOFF_ORCHESTRATOR="$orchestrator"
}

preflight_checks() {
  [[ -d "$SOURCE_AGENTS_DIR" ]] || die "Source does not include an agents directory"

  case "$MODE" in
    agent)
      preflight_agent
      ;;
    handoff)
      preflight_handoff
      ;;
    *)
      die "Invalid mode: $MODE"
      ;;
  esac

  check_destination_writable
}

copy_agent_file() {
  local src="$1"
  local dest_dir="$2"
  mkdir -p "$dest_dir"
  cp "$src" "$dest_dir/"
  info "  copied $(basename "$src") -> $dest_dir/"
}

verify_agent_file() {
  local src="$1"
  local dest="$2"
  
  [[ -f "$dest" ]] || return 1
  grep -q "^name:" "$dest" || return 1
  grep -q "^description:" "$dest" || return 1
  return 0
}

record_installation() {
  local record_file="$DEST/.installed_${NAME}"
  local timestamp
  local agents_list
  
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  agents_list="$(printf '%s\n' "${AGENTS_TO_COPY[@]}" | xargs -I{} basename {} .agent.md | tr '\n' ',' | sed 's/,$//')"
  
  cat > "$record_file" <<EOF
HANDOFF_NAME=$NAME
TIMESTAMP=$timestamp
AGENTS_INSTALLED=$agents_list
SOURCE_ROOT=$SOURCE_ROOT
DESTINATION=$DEST
EOF
  
  info "  recorded metadata -> $record_file"
}

verify_installation() {
  local src=""
  local dest_file=""
  local verified_count=0
  
  info "Verifying installation..."
  
  for src in "${AGENTS_TO_COPY[@]}"; do
    dest_file="$DEST/$(basename "$src")"

    if verify_agent_file "$src" "$dest_file"; then
      info "  ✓ $(basename "$src")"
      ((verified_count++))
    else
      warn "  ✗ $(basename "$src") — file missing or malformed"
    fi
  done
  
  if [[ $verified_count -eq ${#AGENTS_TO_COPY[@]} ]]; then
    info "All agents verified successfully."
    return 0
  else
    warn "$verified_count of ${#AGENTS_TO_COPY[@]} agents verified."
    return 1
  fi
}

install_agent_mode() {
  info "Installing agent '$NAME' -> $DEST"
  copy_agent_file "${AGENTS_TO_COPY[0]}" "$DEST"
  
  if verify_agent_file "${AGENTS_TO_COPY[0]}" "$DEST/$(basename "${AGENTS_TO_COPY[0]}")" 2>/dev/null; then
    info "Installation successful: agent '$NAME' is ready to use."
  else
    warn "Installation completed but agent file verification failed."
  fi
}

install_handoff_mode() {
  local src=""

  info "Installing handoff '$NAME' -> $DEST"

  for src in "${AGENTS_TO_COPY[@]}"; do
    copy_agent_file "$src" "$DEST"
  done

  record_installation
  
  if verify_installation; then
    info "Installation successful: handoff '$NAME' is ready to use."
  else
    warn "Installation completed with verification issues. Please check the files above."
  fi
}

main() {
  parse_args "$@"
  resolve_dest
  resolve_source_layout

  info "Source root: $SOURCE_ROOT"
  info "Destination: $DEST"

  preflight_checks

  case "$MODE" in
    agent)
      install_agent_mode
      ;;
    handoff)
      install_handoff_mode
      ;;
  esac
}

main "$@"
