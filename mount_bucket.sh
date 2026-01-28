#!/usr/bin/env bash
#
# Mounts the DigitalOcean Spaces Bucket defined in .env;

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
MOUNT_POINT="${1:-$ROOT_DIR/bucket}"
BACKGROUND="${BACKGROUND:-1}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Cannot find .env at $ENV_FILE" >&2
  exit 1
fi

# Load SPACES_* variables from the repo's .env file.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${BUCKET_NAME:?Set BUCKET_NAME in .env}"
: "${BUCKET_REGION:?Set BUCKET_REGION in .env}"
: "${BUCKET_KEY_ID:?Set BUCKET_KEY_ID in .env}"
: "${BUCKET_KEY_SECRET:?Set BUCKET_KEY_SECRET in .env}"

mkdir -p "$MOUNT_POINT"

export AWS_ACCESS_KEY_ID="$BUCKET_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$BUCKET_KEY_SECRET"
export AWS_REGION="$BUCKET_REGION"
export AWS_ENDPOINT_URL="https://${BUCKET_REGION}.digitaloceanspaces.com"

echo "Mounting bucket '$BUCKET_NAME' to $MOUNT_POINT"
echo "Using endpoint $AWS_ENDPOINT_URL"

OS_NAME="$(uname -s)"
if [[ "$OS_NAME" == "Darwin" ]]; then
  if ! command -v rclone >/dev/null 2>&1; then
    echo "rclone not found in PATH. Install it via: brew install rclone" >&2
    exit 1
  fi

  if rclone help nfsmount >/dev/null 2>&1; then
    CMD=(
      rclone nfsmount
      ":s3:${BUCKET_NAME}"
      "$MOUNT_POINT"
      --s3-provider "DigitalOcean"
      --s3-endpoint "$AWS_ENDPOINT_URL"
      --s3-region "$BUCKET_REGION"
      --s3-access-key-id "$BUCKET_KEY_ID"
      --s3-secret-access-key "$BUCKET_KEY_SECRET"
    )
    if [[ "$BACKGROUND" == "1" ]]; then
      LOG_FILE="$ROOT_DIR/mount_bucket.log"
      nohup "${CMD[@]}" >"$LOG_FILE" 2>&1 &
      echo "Started in background (PID $!). Logs: $LOG_FILE"
      exit 0
    fi
    exec "${CMD[@]}"
  fi

  echo "rclone nfsmount is not available. Install rclone from https://rclone.org/downloads/ for mount support." >&2
  echo "If you use rclone mount, install macFUSE and enable it in System Settings." >&2
  exit 1
fi

if ! command -v mount-s3 >/dev/null 2>&1; then
  echo "mount-s3 not found in PATH. Install AWS mountpoint for S3 or add it to PATH." >&2
  exit 1
fi

ALLOW_OTHER_FLAG=()
if grep -qE '^[[:space:]]*user_allow_other' /etc/fuse.conf 2>/dev/null; then
  ALLOW_OTHER_FLAG=(--allow-other)
else
  echo "Note: /etc/fuse.conf lacks 'user_allow_other'; mounting without --allow-other."
fi

CMD=(
  mount-s3
  "${ALLOW_OTHER_FLAG[@]}"
  --endpoint-url "$AWS_ENDPOINT_URL"
  "$BUCKET_NAME"
  "$MOUNT_POINT"
)
if [[ "$BACKGROUND" == "1" ]]; then
  LOG_FILE="$ROOT_DIR/mount_bucket.log"
  nohup "${CMD[@]}" >"$LOG_FILE" 2>&1 &
  echo "Started in background (PID $!). Logs: $LOG_FILE"
  exit 0
fi
exec "${CMD[@]}"
