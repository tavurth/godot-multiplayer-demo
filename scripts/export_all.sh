#!/usr/bin/env bash
set -euo pipefail

# Then create exports
bash ./scripts/mac_export.sh
bash ./scripts/win_export.sh
bash ./scripts/linux_export.sh

bash ./scripts/push.sh
