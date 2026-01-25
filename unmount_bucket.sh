#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_POINT="${1:-$ROOT_DIR/bucket}"

fusermount -u $MOUNT_POINT
