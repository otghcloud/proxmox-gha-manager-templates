#!/usr/bin/env bash
set -euo pipefail

CURL_BIN="/usr/bin/curl"
TOKEN="${GITHUB_TOKEN:-}"
MIN_REMAINING="${GITHUB_API_MIN_REMAINING:-10}"
WAIT_BUFFER_SECONDS="${GITHUB_API_WAIT_BUFFER_SECONDS:-15}"

if [[ -z "${TOKEN}" && -f /etc/github-api-token ]]; then
  TOKEN="$(cat /etc/github-api-token)"
fi

if [[ -f /etc/github-api-rate-limit.conf ]]; then
  # shellcheck disable=SC1091
  source /etc/github-api-rate-limit.conf
fi

is_github_api_call=false
for arg in "$@"; do
  if [[ "${arg}" == *"api.github.com"* ]]; then
    is_github_api_call=true
    break
  fi
done

if [[ "${is_github_api_call}" == true ]]; then
  header_file="$(mktemp)"
  trap 'rm -f "${header_file}"' EXIT

  # GET, not HEAD: the API answers HEAD /rate_limit with a 404, which loses the headers
  # this reads and prints a misleading curl error into every build log.
  if [[ -n "${TOKEN}" ]]; then
    "${CURL_BIN}" -fsSL -H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github+json" -o /dev/null -D "${header_file}" https://api.github.com/rate_limit || true
  else
    "${CURL_BIN}" -fsSL -H "Accept: application/vnd.github+json" -o /dev/null -D "${header_file}" https://api.github.com/rate_limit || true
  fi

  remaining="$(awk -F': ' 'tolower($1)=="x-ratelimit-remaining" {gsub("\r","",$2); print $2}' "${header_file}" | tail -n1 || true)"
  reset_epoch="$(awk -F': ' 'tolower($1)=="x-ratelimit-reset" {gsub("\r","",$2); print $2}' "${header_file}" | tail -n1 || true)"

  if [[ -n "${remaining}" && -n "${reset_epoch}" ]] && (( remaining <= MIN_REMAINING )); then
    now="$(date +%s)"
    wait_seconds=$(( reset_epoch - now + WAIT_BUFFER_SECONDS ))
    if (( wait_seconds > 0 )); then
      echo "[gh-api-wrapper] remaining ${remaining} below threshold ${MIN_REMAINING}; sleeping ${wait_seconds}s" >&2
      sleep "${wait_seconds}"
    fi
  fi

  if [[ -n "${TOKEN}" ]]; then
    exec "${CURL_BIN}" -H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github+json" "$@"
  fi
fi

exec "${CURL_BIN}" "$@"
