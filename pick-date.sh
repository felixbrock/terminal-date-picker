#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  fi

  printf 'Error: bash is required.\n' >&2
  exit 1
fi

set -eu
set -o pipefail 2>/dev/null || true

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_path="$script_dir/$(basename "${BASH_SOURCE[0]}")"

print_only=0
filter=""
preview_line=""
start_year=""
end_year=""

usage() {
  printf 'Usage: %s [--print-only] [--filter TEXT] [START_YEAR [END_YEAR]]\n' "$(basename "$0")" >&2
}

while (($#)); do
  case "$1" in
    --print-only)
      print_only=1
      shift
      ;;
    --filter)
      if (($# < 2)); then
        usage
        exit 1
      fi
      filter="$2"
      shift 2
      ;;
    --preview)
      if (($# < 2)); then
        usage
        exit 1
      fi
      preview_line="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$start_year" ]]; then
        start_year="$1"
        shift
      elif [[ -z "$end_year" ]]; then
        end_year="$1"
        shift
      else
        usage
        exit 1
      fi
      ;;
  esac
done

current_year="$(date +%Y)"
start_year="${start_year:-$current_year}"
end_year="${end_year:-$((start_year + 9))}"

if ! [[ "$start_year" =~ ^[0-9]{4}$ ]] || ! [[ "$end_year" =~ ^[0-9]{4}$ ]]; then
  usage
  exit 1
fi

if ((end_year < start_year)); then
  printf 'Error: END_YEAR must be greater than or equal to START_YEAR.\n' >&2
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  printf 'Error: fzf is required.\n' >&2
  exit 1
fi

fzf_args=()
if [[ -n "$filter" ]]; then
  fzf_args+=(--filter "$filter")
fi

copy_to_clipboard() {
  local text
  text="$1"

  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$text" | wl-copy
    return 0
  fi

  if [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
    printf '%s' "$text" | xclip -selection clipboard
    return 0
  fi

  if [[ -n "${DISPLAY:-}" ]] && command -v xsel >/dev/null 2>&1; then
    printf '%s' "$text" | xsel --clipboard --input
    return 0
  fi

  if command -v termux-clipboard-set >/dev/null 2>&1; then
    termux-clipboard-set "$text"
    return 0
  fi

  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$text" | pbcopy
    return 0
  fi

  return 1
}

dates_for_year() {
  local today
  today="$(date +%F)"

  python3 - "$start_year" "$end_year" "$today" <<'PY'
from datetime import date, timedelta
import sys

start_year = int(sys.argv[1])
end_year = int(sys.argv[2])
today = date.fromisoformat(sys.argv[3])

current = max(date(start_year, 1, 1), today)
last = date(end_year, 12, 31)

while current <= last:
    weekday_occurrence = (current.day - 1) // 7 + 1
    if weekday_occurrence == 1:
        ordinal = "1st"
    elif weekday_occurrence == 2:
        ordinal = "2nd"
    elif weekday_occurrence == 3:
        ordinal = "3rd"
    else:
        ordinal = f"{weekday_occurrence}th"

    picker_label = f"{current.strftime('%a %d %b %Y')} {ordinal}"
    print(f"{current.isoformat()}\t{picker_label}")
    current += timedelta(days=1)
PY
}

ordinal_suffix() {
  local n
  n="$1"

  case "$n" in
    1) printf '1st' ;;
    2) printf '2nd' ;;
    3) printf '3rd' ;;
    *) printf '%sth' "$n" ;;
  esac
}

python_date() {
  python3 - "$@" <<'PY'
from datetime import date
import sys

mode = sys.argv[1]
selected = date.fromisoformat(sys.argv[2])

if mode == "weekday-short":
    print(selected.strftime("%a"))
elif mode == "picker-label":
    weekday_occurrence = (selected.day - 1) // 7 + 1
    if weekday_occurrence == 1:
        ordinal = "1st"
    elif weekday_occurrence == 2:
        ordinal = "2nd"
    elif weekday_occurrence == 3:
        ordinal = "3rd"
    else:
        ordinal = f"{weekday_occurrence}th"
    print(f"{selected.strftime('%a %d %b %Y')} {ordinal}")
elif mode == "selected-long":
    print(selected.strftime("%A, %d %B %Y"))
elif mode == "month-start":
    print(selected.replace(day=1).isoformat())
elif mode == "month":
    print(selected.strftime("%m"))
elif mode == "year":
    print(selected.strftime("%Y"))
else:
    raise SystemExit(f"Unsupported mode: {mode}")
PY
}

format_output() {
  local selected weekday_label
  selected="$1"
  weekday_label="$(python_date weekday-short "$selected")"

  printf '%s %s\n' \
    "$weekday_label" \
    "$selected"
}

format_picker_label() {
  local selected
  selected="$1"
  python_date picker-label "$selected"
}

render_preview() {
  local selected month_start
  selected="${preview_line%%$'\t'*}"
  month_start="$(python_date month-start "$selected")"

  printf 'Selected: %s\n' "$(python_date selected-long "$selected")"
  printf 'Copy as: %s\n\n' "$(format_output "$selected")"
  cal -3 "$(python_date month "$month_start")" "$(python_date year "$month_start")"
}

if [[ -n "$preview_line" ]]; then
  render_preview
  exit 0
fi

date_candidates="$(dates_for_year)"

if [[ -z "$date_candidates" ]]; then
  printf 'No dates available in the selected range.\n' >&2
  exit 1
fi

selected_date="$(
  fzf \
    --delimiter=$'\t' \
    --with-nth=1,2 \
    --prompt='Pick date > ' \
    --header="Enter: copy date | Esc: cancel | Range: ${start_year}-${end_year}" \
    "${fzf_args[@]}" \
    --preview "$script_path --preview {}" \
    --preview-window='right,60%,border-left' \
    <<< "$date_candidates"
)"

if [[ -z "${selected_date:-}" ]]; then
  exit 130
fi

selected_date="${selected_date%%$'\t'*}"
formatted_output="$(format_output "$selected_date")"

if ((print_only)); then
  printf '%s\n' "$formatted_output"
  exit 0
fi

printf '%s\n' "$formatted_output"

if ! copy_to_clipboard "$formatted_output"; then
  printf 'No supported clipboard tool found; printed the selected date instead.\n' >&2
  exit 0
fi

printf 'Copied %s to clipboard.\n' "$formatted_output" >&2
