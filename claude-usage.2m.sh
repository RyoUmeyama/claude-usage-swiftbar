#!/bin/bash

# Claude Usage Monitor for SwiftBar
# Refreshes every 2 minutes (configured via filename: claude-usage.2m.sh)

# Get OAuth token from macOS Keychain
CREDS=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
if [ -z "$CREDS" ]; then
  echo "☁️ --"
  echo "---"
  echo "Claude Code credentials not found in Keychain"
  exit 0
fi

ACCESS_TOKEN=$(echo "$CREDS" | python3 -c "import sys,json; print(json.load(sys.stdin)['claudeAiOauth']['accessToken'])" 2>/dev/null)
if [ -z "$ACCESS_TOKEN" ]; then
  echo "☁️ --"
  echo "---"
  echo "Failed to parse access token"
  exit 0
fi

# Fetch usage data
USAGE=$(curl -s --max-time 10 'https://api.anthropic.com/api/oauth/usage' \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H 'anthropic-beta: oauth-2025-04-20' \
  -H 'User-Agent: claude-code/2.0.37')

if [ -z "$USAGE" ]; then
  echo "☁️ --"
  echo "---"
  echo "Failed to fetch usage data"
  exit 0
fi

# Parse JSON with Python
export USAGE_JSON="$USAGE"
read -r FIVE_HOUR_UTIL FIVE_HOUR_RESET SEVEN_DAY_UTIL SEVEN_DAY_RESET SONNET_UTIL SONNET_RESET <<< $(python3 << 'PYEOF'
import json, sys, os
from datetime import datetime, timezone

raw = os.environ.get("USAGE_JSON", "")
try:
    d = json.loads(raw)
except:
    print("0 -- 0 -- 0 --")
    sys.exit(0)

def parse_bucket(bucket):
    if not bucket:
        return "0", "--"
    util = bucket.get("utilization", 0)
    reset = bucket.get("resets_at", "")
    if reset:
        try:
            dt = datetime.fromisoformat(reset)
            now = datetime.now(timezone.utc)
            diff = dt - now
            total_min = int(diff.total_seconds() / 60)
            if total_min < 0:
                time_str = "now"
            elif total_min < 60:
                time_str = f"{total_min}m"
            else:
                h = total_min // 60
                m = total_min % 60
                time_str = f"{h}h{m:02d}m"
        except:
            time_str = "--"
    else:
        time_str = "--"
    return str(util), time_str

fh_util, fh_reset = parse_bucket(d.get("five_hour"))
sd_util, sd_reset = parse_bucket(d.get("seven_day"))
sn_util, sn_reset = parse_bucket(d.get("seven_day_sonnet"))

print(f"{fh_util} {fh_reset} {sd_util} {sd_reset} {sn_util} {sn_reset}")
PYEOF
)

# Determine color based on 5-hour utilization
FIVE_HOUR_INT=${FIVE_HOUR_UTIL%.*}
if [ "$FIVE_HOUR_INT" -ge 90 ] 2>/dev/null; then
  COLOR="#FF3B30"
  ICON="🔴"
elif [ "$FIVE_HOUR_INT" -ge 70 ] 2>/dev/null; then
  COLOR="#FF9500"
  ICON="🟠"
elif [ "$FIVE_HOUR_INT" -ge 50 ] 2>/dev/null; then
  COLOR="#FFCC00"
  ICON="🟡"
else
  COLOR="#34C759"
  ICON="🟢"
fi

# Menu bar title
echo "${ICON} ${FIVE_HOUR_UTIL}% | color=$COLOR size=13"
echo "---"

# Progress bar helper
make_bar() {
  local val=${1%.*}
  local total=20
  local filled=$((val * total / 100))
  local empty=$((total - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo "$bar"
}

# Dropdown details
echo "Claude Usage | size=14 font=Menlo"
echo "---"

BAR5=$(make_bar "$FIVE_HOUR_UTIL")
echo "⏱ Session (5h)   ${FIVE_HOUR_UTIL}% | font=Menlo size=13"
echo "  ${BAR5}  reset: ${FIVE_HOUR_RESET} | font=Menlo size=12 color=$COLOR"
echo "---"

BAR7=$(make_bar "$SEVEN_DAY_UTIL")
SEVEN_DAY_INT=${SEVEN_DAY_UTIL%.*}
if [ "$SEVEN_DAY_INT" -ge 80 ] 2>/dev/null; then
  COLOR7="#FF3B30"
elif [ "$SEVEN_DAY_INT" -ge 60 ] 2>/dev/null; then
  COLOR7="#FF9500"
else
  COLOR7="#34C759"
fi
echo "📊 Weekly (7d)    ${SEVEN_DAY_UTIL}% | font=Menlo size=13"
echo "  ${BAR7}  reset: ${SEVEN_DAY_RESET} | font=Menlo size=12 color=$COLOR7"
echo "---"

BARS=$(make_bar "$SONNET_UTIL")
echo "💬 Sonnet (7d)    ${SONNET_UTIL}% | font=Menlo size=13"
echo "  ${BARS}  reset: ${SONNET_RESET} | font=Menlo size=12 color=#34C759"
echo "---"

echo "Open Usage Page | href=https://claude.ai/settings/usage"
echo "Refresh | refresh=true"
