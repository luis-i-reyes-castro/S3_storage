#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_POINT="${1:-$ROOT_DIR/bucket}"

OS_NAME="$(uname -s)"
if [[ "$OS_NAME" == "Darwin" ]]; then
  if command -v diskutil >/dev/null 2>&1; then
    if ! diskutil unmount "$MOUNT_POINT" >/dev/null 2>&1; then
      diskutil unmount force "$MOUNT_POINT" >/dev/null
    fi
    echo "Unmounted $MOUNT_POINT"
  else
    umount "$MOUNT_POINT"
  fi
else
  if command -v fusermount >/dev/null 2>&1; then
    fusermount -u "$MOUNT_POINT"
  else
    umount "$MOUNT_POINT"
  fi
fi
