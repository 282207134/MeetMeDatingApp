#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
MEETME_DEVICE_ID="${1:-687B0ECD-3A39-4DF8-8916-3CC213A0D3E8}"
flutter pub get
flutter run -d "$MEETME_DEVICE_ID"
