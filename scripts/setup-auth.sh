#!/usr/bin/env bash
# First-time Google authentication for NotebookLM Playwright automation.
# Run this once (or whenever the Google session expires) to save credentials
# to the persistent profile at /root/.playwright-notebooklm-profile.
#
# Usage: ./scripts/setup-auth.sh [--restore-from-drive]

set -euo pipefail

PROFILE_DIR="/root/.playwright-notebooklm-profile"
NOTEBOOKLM_URL="https://notebooklm.google.com/notebook/3865a42e-1acc-488e-8e7f-65f15e7b34f9"
DRIVE_BACKUP_NAME="playwright-notebooklm-profile.tar.gz"

log() { echo "[setup-auth] $*"; }
die() { echo "[setup-auth] ERROR: $*" >&2; exit 1; }

if [[ "${1:-}" == "--restore-from-drive" ]]; then
  log "Restoring profile from Google Drive backup..."
  BACKUP="/tmp/${DRIVE_BACKUP_NAME}"
  [[ -f "$BACKUP" ]] || die "Backup file not found at $BACKUP. Download it from Drive first."
  rm -rf "$PROFILE_DIR"
  mkdir -p "$PROFILE_DIR"
  tar -xzf "$BACKUP" -C "$(dirname "$PROFILE_DIR")"
  log "Profile restored to $PROFILE_DIR"
  exit 0
fi

log "Checking dependencies..."

if ! command -v Xvfb &>/dev/null; then
  log "Installing Xvfb..."
  apt-get update -q && apt-get install -y -q xvfb
fi

if ! command -v npx &>/dev/null; then
  die "npx not found. Install Node.js first."
fi

log "Ensuring Playwright Chromium is installed..."
npx -y playwright@latest install chromium --with-deps 2>&1 | tail -5

log "Starting virtual display (Xvfb :99)..."
Xvfb :99 -screen 0 1280x800x24 &
XVFB_PID=$!
export DISPLAY=:99
sleep 1

cleanup() { kill "$XVFB_PID" 2>/dev/null || true; }
trap cleanup EXIT

log ""
log "=========================================================="
log "  Opening Chromium for manual Google login."
log "  1. Sign in to your Google account when prompted."
log "  2. Navigate to NotebookLM and confirm access."
log "  3. Close the browser window when done."
log "  Profile will be saved to: $PROFILE_DIR"
log "=========================================================="
log ""

mkdir -p "$PROFILE_DIR"

npx -y playwright@latest open \
  --browser chromium \
  --user-data-dir "$PROFILE_DIR" \
  "$NOTEBOOKLM_URL" || true

log "Browser closed. Profile saved to $PROFILE_DIR"

BACKUP="/tmp/${DRIVE_BACKUP_NAME}"
log "Creating backup archive at $BACKUP ..."
tar -czf "$BACKUP" -C "$(dirname "$PROFILE_DIR")" "$(basename "$PROFILE_DIR")"
log "Backup created: $BACKUP"
log "Setup complete. Playwright will reuse this profile automatically."
