#!/usr/bin/env bash
# Resolve ublue's base image tag to a digest, verify its signature, and print it for the build.
set -euo pipefail
REPO=ghcr.io/ublue-os/base-nvidia
TAG=${TAG:-latest}
KEY=${KEY:-ublue-os.pub}

digest=$(skopeo inspect --format '{{.Digest}}' "docker://$REPO:$TAG")
cosign verify --key "$KEY" "$REPO@$digest" >/dev/null
echo "Using $REPO:$TAG $digest" >&2
echo "BASE_IMAGE=$REPO@$digest"
