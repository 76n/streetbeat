#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JSON_PATH="${1:-$ROOT/android/app/google-services.json}"

echo "StreetBeat — Firebase config check"
echo "File: $JSON_PATH"
echo ""

if [[ ! -f "$JSON_PATH" ]]; then
  echo "ERROR: google-services.json not found."
  echo "Download it from Firebase Console → Project settings → Your apps → Android."
  echo "Expected path: android/app/google-services.json"
  exit 1
fi

if command -v jq &>/dev/null; then
  PROJECT_ID=$(jq -r '.project_info.project_id // empty' "$JSON_PATH")
  API_KEY=$(jq -r '.client[0].api_key[0].current_key // empty' "$JSON_PATH")
  APP_ID=$(jq -r '.client[0].client_info.mobilesdk_app_id // empty' "$JSON_PATH")
else
  PROJECT_ID=$(python3 -c "
import json
with open('$JSON_PATH') as f:
    d = json.load(f)
print(d.get('project_info', {}).get('project_id') or '')
")
  API_KEY=$(python3 -c "
import json
with open('$JSON_PATH') as f:
    d = json.load(f)
try:
    print(d['client'][0]['api_key'][0]['current_key'])
except (KeyError, IndexError):
    print('')
")
  APP_ID=$(python3 -c "
import json
with open('$JSON_PATH') as f:
    d = json.load(f)
try:
    print(d['client'][0]['client_info']['mobilesdk_app_id'])
except (KeyError, IndexError):
    print('')
")
fi

ERR=0

check_non_empty() {
  local name="$1"
  local val="$2"
  if [[ -z "${val// }" ]]; then
    echo "ERROR: Missing required field: $name"
    ERR=1
  else
    echo "OK: $name is set"
  fi
}

check_non_empty "project_id (project_info.project_id)" "$PROJECT_ID"
check_non_empty "api_key (client[0].api_key[0].current_key)" "$API_KEY"
check_non_empty "app_id (client[0].client_info.mobilesdk_app_id)" "$APP_ID"

looks_placeholder() {
  local v
  v=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  [[ "$v" == *"your_"* ]] || [[ "$v" == *"placeholder"* ]] || [[ "$v" == *"example"* ]] \
    || [[ "$v" == *"changeme"* ]] || [[ "$v" == *"replace"* ]] || [[ "$v" == *"todo"* ]]
}

if [[ $ERR -eq 0 ]]; then
  if looks_placeholder "$PROJECT_ID" || looks_placeholder "$API_KEY" || looks_placeholder "$APP_ID"; then
    echo ""
    echo "ERROR: One or more values still look like placeholders (your_, placeholder, example, …)."
    echo "Replace android/app/google-services.json with the real file from Firebase."
    ERR=1
  fi
fi

if [[ $ERR -ne 0 ]]; then
  echo ""
  echo "Fix the issues above, then re-run: ./scripts/setup_firebase.sh"
  exit 1
fi

echo ""
echo "google-services.json looks valid for StreetBeat."
