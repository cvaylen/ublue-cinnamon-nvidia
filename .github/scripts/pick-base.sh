#!/usr/bin/env bash
# Pick the newest ublue base image whose signature was logged in Rekor at least MIN_AGE_DAYS ago.
set -euo pipefail
REPO=ghcr.io/ublue-os/base-nvidia
KEY=${KEY:-ublue-os.pub}
MIN_AGE=$(( ${MIN_AGE_DAYS:-3} * 86400 ))
now=$(date +%s)
cutoff="latest-$(date -u -d "@$(( now - MIN_AGE ))" +%Y%m%d)"

mapfile -t candidates < <(
  skopeo list-tags "docker://$REPO" | jq -r '.Tags[]' |
    grep -E '^latest-[0-9]{8}$' | sort -r | awk -v c="$cutoff" '$0 <= c' | head -n 5
)

for tag in "${candidates[@]}"; do
  digest=$(skopeo inspect --format '{{.Digest}}' "docker://$REPO:$tag")
  if ! sigs=$(cosign verify --key "$KEY" "$REPO@$digest" 2>/dev/null); then
    echo "skip $tag: signature does not verify" >&2
    continue
  fi
  signed=$(jq '[.[].optional.Bundle.Payload.integratedTime] | min' <<<"$sigs")
  if (( now - signed < MIN_AGE )); then
    echo "skip $tag: signed $(date -u -d "@$signed") is too recent" >&2
    continue
  fi
  echo "Using $tag $digest (signed $(date -u -d "@$signed"))" >&2
  echo "BASE_IMAGE=$REPO@$digest"
  exit 0
done

echo "No verified base image at least $(( MIN_AGE / 86400 )) days old" >&2
exit 1
