#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Использование:
  stsuf --path DIR
USAGE
}

DIR=""

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      [[ $# -ge 2 ]] || { echo "Для --path нужен аргумент" >&2; exit 1; }
      DIR="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Неизвестный аргумент: $1" >&2
      usage; exit 1;;
  esac
done

[[ -d "$DIR" ]] || { echo "Ошибка: '$DIR' не каталог" >&2; exit 1; }

declare -A counts

export LC_ALL=C
while IFS= read -r -d '' f; do
  base="$(basename -- "$f")"
  if [[ "$base" == *.* ]]; then
    idx="${base##*.}"
    if [[ "${base:0:1}" == "." && "$base" != *.*.* ]]; then
      key="no suffix"
    else
      suffix=".${idx}"
      key="$suffix"
    fi
  else
    key="no suffix"
  fi
  counts["$key"]=$(( ${counts["$key"]:-0} + 1 ))
done < <(find "$DIR" -type f -print0)

{
  for k in "${!counts[@]}"; do
    printf "%d\t%s\n" "${counts[$k]}" "$k"
  done
} | sort -nr | awk -F'\t' '{print $2 ": " $1}'
