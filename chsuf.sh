#!/usr/bin/env bash
set -euo pipefail

print_usage_chsuf() {
  cat <<'USAGE'
Использование:
  chsuf --path DIR --old OLD_SUFFIX --new NEW_SUFFIX

Примеры:
  chsuf --path /data --old '.log' --new '.txt'
  chsuf --path /proj --old '.bak' --new '.old'
USAGE
}

DIR=""
OLD=""
NEW=""

if [[ $# -eq 0 ]]; then
  print_usage_chsuf
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      [[ $# -ge 2 ]] || { echo "Для --path нужен аргумент" >&2; exit 1; }
      DIR="$2"; shift 2;;
    --old)
      [[ $# -ge 2 ]] || { echo "Для --old нужен аргумент" >&2; exit 1; }
      OLD="$2"; shift 2;;
    --new)
      [[ $# -ge 2 ]] || { echo "Для --new нужен аргумент" >&2; exit 1; }
      NEW="$2"; shift 2;;
    -h|--help)
      print_usage_chsuf; exit 0;;
    *)
      echo "Неизвестный аргумент: $1" >&2
      print_usage_chsuf
      exit 1;;
  esac
done

if [[ -z "$DIR" || -z "$OLD" || -z "$NEW" ]]; then
  print_usage_chsuf
  exit 1
fi

[[ -d "$DIR" ]] || { echo "Ошибка: '$DIR' не каталог" >&2; exit 1; }

if [[ ! "$OLD" =~ ^\.[^.]+$ ]]; then
  echo "Ошибка: старый суффикс должен соответствовать ^\\.[^.]+\$" >&2
  exit 1
fi
if [[ ! "$NEW" =~ ^\.[^.]+$ ]]; then
  echo "Ошибка: новый суффикс должен соответствовать ^\\.[^.]+\$" >&2
  exit 1
fi

export LC_ALL=C
while IFS= read -r -d '' f; do
  base="$(basename -- "$f")"
  if [[ "$base" == *"$OLD" ]]; then
    prefix="${base%$OLD}"
    if [[ -n "$prefix" ]]; then
      newbase="${prefix}${NEW}"
      newpath="$(dirname -- "$f")/$newbase"
      if [[ "$f" != "$newpath" ]]; then
        mv -n -- "$f" "$newpath"
        echo "Переименовано: $f -> $newpath"
      fi
    fi
  fi
done < <(find "$DIR" -type f -print0)
