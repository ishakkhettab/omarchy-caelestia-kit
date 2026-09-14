#!/usr/bin/env bash
set -euo pipefail
clear
cat <<'EOF'
================================================
  Caelestia looks install for Omarchy
  Super+Space and Super+K stay the same
  Type your sudo password when asked
================================================

EOF
/home/khettabishak/.local/share/omarchy-caelestia/install.sh
status=$?
echo
if [[ $status -eq 0 ]]; then
  echo OK
else
  echo "FAILED ($status)"
fi
echo
echo "Press Enter to close."
read -r
