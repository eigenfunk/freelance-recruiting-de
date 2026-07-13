#!/usr/bin/env bash
# Verify that the domains excluded in lychee.toml are still alive.
#
# Run this LOCALLY from a residential IP. Do NOT run it in CI:
# these domains are excluded precisely because they block/throttle
# GitHub's datacenter IP range, so a CI run would only reproduce
# the timeouts the exclude list works around.
#
# For every exclude pattern in lychee.toml, all matching URLs in
# readme.md are checked: follow redirects, require HTTP 200 and a
# page title that does not look like an error page (soft-404 guard).
set -uo pipefail

cd "$(dirname "$0")"

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
MAX_TIME=30

# Extract plain domains from the exclude patterns, e.g.
#   exclude = ["projekt-broker\\.com", "constaff\\.com"]
# -> projekt-broker.com constaff.com
domains=$(grep -E '^exclude' lychee.toml | grep -oE '"[^"]+"' | tr -d '"' | sed 's/\\//g')

if [ -z "$domains" ]; then
    echo "No exclude entries found in lychee.toml - nothing to check."
    exit 0
fi

fail=0

for domain in $domains; do
    urls=$(grep -oE "https?://[^)> ]*${domain}[^)> ]*" readme.md | sort -u)

    if [ -z "$urls" ]; then
        echo "WARN  $domain: excluded but no URL found in readme.md (stale exclude?)"
        fail=1
        continue
    fi

    for url in $urls; do
        result=$(curl -sSL -o /dev/null --max-time "$MAX_TIME" -A "$UA" \
            -w "%{http_code} %{time_total} %{url_effective}" "$url" 2>/dev/null)

        if [ -z "$result" ]; then
            echo "FAIL  $url: curl error (timeout or connection refused)"
            fail=1
            continue
        fi

        read -r code time_total final_url <<< "$result"

        if [ "$code" != "200" ]; then
            echo "FAIL  $url: HTTP $code (final: $final_url)"
            fail=1
            continue
        fi

        # Soft-404 guard: a 200 whose title looks like an error page
        title=$(curl -sSL --max-time "$MAX_TIME" -A "$UA" "$url" 2>/dev/null \
            | grep -ioE '<title>[^<]*' | head -1 | sed 's/<title>//I')

        if echo "$title" | grep -qiE '404|not found|nicht gefunden|fehler|error'; then
            echo "FAIL  $url: HTTP 200 but title looks like an error page: \"$title\""
            fail=1
            continue
        fi

        printf "OK    %s  (%ss)  \"%s\"\n" "$url" "${time_total%[0-9][0-9][0-9][0-9][0-9]}" "$title"
    done
done

if [ "$fail" -ne 0 ]; then
    echo
    echo "At least one excluded domain failed - check whether it is really"
    echo "still alive or should be removed from readme.md and lychee.toml."
    exit 1
fi

echo
echo "All excluded domains are alive."
