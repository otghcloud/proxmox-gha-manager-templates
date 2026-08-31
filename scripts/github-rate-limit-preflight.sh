#!/usr/bin/env bash
set -euo pipefail

TOKEN="${GITHUB_TOKEN:-${PACKER_GITHUB_API_TOKEN:-}}"
MIN_REMAINING="${GITHUB_API_MIN_REMAINING:-10}"
WAIT_BUFFER_SECONDS="${GITHUB_API_WAIT_BUFFER_SECONDS:-15}"

header_file="$(mktemp)"
trap 'rm -f "${header_file}"' EXIT

if [[ -n "${TOKEN}" ]]; then
  curl -fsSIL -H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github+json" https://api.github.com/rate_limit > "${header_file}" || true
else
  curl -fsSIL -H "Accept: application/vnd.github+json" https://api.github.com/rate_limit > "${header_file}" || true
fi

remaining="$(awk -F': ' 'tolower($1)=="x-ratelimit-remaining" {gsub("\r","",$2); print $2}' "${header_file}" | tail -n1)"
reset_epoch="$(awk -F': ' 'tolower($1)=="x-ratelimit-reset" {gsub("\r","",$2); print $2}' "${header_file}" | tail -n1)"

if [[ -z "${remaining}" || -z "${reset_epoch}" ]]; then
  echo "==> GitHub API preflight: could not parse rate-limit headers, continuing without wait"
  exit 0
fi

if (( remaining > MIN_REMAINING )); then
  echo "==> GitHub API preflight: remaining ${remaining}, above threshold ${MIN_REMAINING}"
  exit 0
fi

now="$(date +%s)"
wait_seconds=$(( reset_epoch - now + WAIT_BUFFER_SECONDS ))
if (( wait_seconds <= 0 )); then
  echo "==> GitHub API preflight: remaining ${remaining}, reset window already passed"
  exit 0
fi

echo "==> GitHub API preflight: remaining ${remaining}, sleeping ${wait_seconds}s until reset"
sleep "${wait_seconds}"
