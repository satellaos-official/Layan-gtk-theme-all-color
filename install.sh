#!/bin/bash
#
# Layan GTK theme installer
#
# Usage:
#   bash install.sh -u        Install for the current user only  (no sudo)   -> $HOME/.themes/
#   sudo bash install.sh -s   Install system-wide                (sudo)      -> /usr/share/themes/
#   sudo bash install.sh -a   Install for future new users        (sudo)      -> /etc/skel/.themes/
#
# Flags can be combined, e.g.: sudo bash install.sh -s -a

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="/tmp/themes"
ARCHIVE_DIR="${SCRIPT_DIR}/archive"
ARCHIVE_FILE="${ARCHIVE_DIR}/Layan-all-colors.tar.gz"

# ---------- logging helpers ----------
log_info()  { echo -e "[INFO]  $*"; }
log_ok()    { echo -e "[OK]    $*"; }
log_warn()  { echo -e "[WARN]  $*"; }
log_error() { echo -e "[ERROR] $*" >&2; }

# ---------- usage ----------
usage() {
  cat << EOF
Layan GTK theme installer

Usage:
  bash install.sh -u        Install for the current user only (run WITHOUT sudo)
                             Destination: \$HOME/.themes/

  sudo bash install.sh -s   Install system-wide (run WITH sudo)
                             Destination: /usr/share/themes/

  sudo bash install.sh -a   Install for future new users (run WITH sudo)
                             Destination: /etc/skel/.themes/

Options:
  -u    User install (no sudo)
  -s    System-wide install (sudo required)
  -a    Skeleton (new users) install (sudo required)
  -h    Show this help message

Flags can be combined, e.g.: sudo bash install.sh -s -a
EOF
}

# ---------- extract theme archive into themes/ ----------
extract_archive() {
  if [[ ! -f "${ARCHIVE_FILE}" ]]; then
    log_error "Archive not found: ${ARCHIVE_FILE}"
    exit 1
  fi

  log_info "Extracting theme archive..."
  mkdir -p "${THEME_SRC}"

  if ! tar -xzf "${ARCHIVE_FILE}" -C "${THEME_SRC}"; then
    log_error "Failed to extract ${ARCHIVE_FILE}"
    exit 1
  fi

  log_ok "Extracted archive contents to ${THEME_SRC}"
}

# ---------- remove extracted contents from themes/ after install ----------
deleting_themes() {
  log_info "Deleting up extracted files in ${THEME_SRC}..."
  rm -rf "${THEME_SRC:?}"
  log_ok "Deleting up ${THEME_SRC}"
}

# ---------- sanity check: theme source exists ----------
check_source() {
  if [[ ! -d "${THEME_SRC}" ]]; then
    log_error "Theme source directory not found: ${THEME_SRC}"
    exit 1
  fi
  if ! compgen -G "${THEME_SRC}/Layan-*" > /dev/null; then
    log_error "No 'Layan-*' theme folders found in ${THEME_SRC}"
    exit 1
  fi
}

# ---------- is this invocation running as root? ----------
is_root() {
  [[ "${EUID}" -eq 0 ]]
}

# ---------- actions ----------
install_user() {
  log_info "Starting user install..."

  if is_root; then
    log_error "The user install (-u) must be run WITHOUT sudo."
    log_error "Please run it as: bash install.sh -u"
    log_warn  "Skipping user install."
    return 1
  fi

  local dest="${HOME}/.themes"
  mkdir -p "${dest}"
  cp -r "${THEME_SRC}"/Layan-* "${dest}/"
  log_ok "Installed theme(s) to ${dest}"
}

install_system() {
  log_info "Starting system-wide install..."

  if ! is_root; then
    log_error "The system-wide install (-s) requires root privileges."
    log_error "Please run it as: sudo bash install.sh -s"
    log_warn  "Skipping system-wide install."
    return 1
  fi

  local dest="/usr/share/themes"
  mkdir -p "${dest}"
  cp -r "${THEME_SRC}"/Layan-* "${dest}/"
  log_ok "Installed theme(s) to ${dest}"
}

install_skel() {
  log_info "Starting skeleton (new users) install..."

  if ! is_root; then
    log_error "The skeleton install (-a) requires root privileges."
    log_error "Please run it as: sudo bash install.sh -a"
    log_warn  "Skipping skeleton install."
    return 1
  fi

  local dest="/etc/skel/.themes"
  mkdir -p "${dest}"
  cp -r "${THEME_SRC}"/Layan-* "${dest}/"
  log_ok "Installed theme(s) to ${dest}"
}

# ---------- argument parsing ----------
if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

DO_USER=false
DO_SYSTEM=false
DO_SKEL=false

while getopts ":usah" opt; do
  case "${opt}" in
    u) DO_USER=true ;;
    s) DO_SYSTEM=true ;;
    a) DO_SKEL=true ;;
    h) usage; exit 0 ;;
    \?) log_error "Unknown option: -${OPTARG}"; usage; exit 1 ;;
  esac
done

extract_archive
check_source

STATUS=0

if ${DO_SYSTEM}; then
  install_system || STATUS=1
fi

if ${DO_SKEL}; then
  install_skel || STATUS=1
fi

if ${DO_USER}; then
  install_user || STATUS=1
fi

deleting_themes

exit ${STATUS}
