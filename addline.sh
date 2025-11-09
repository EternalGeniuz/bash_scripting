set -euo pipefail

usage() {
  cat <<'USAGE'
Использование:
  addline --path DIR
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

USER_NAME="${USER:-$(whoami)}"
DATE_STR="$(date -Iseconds)"

shopt -s nullglob
for f in "$DIR"/*.txt; do
  [[ -f "$f" ]] || continue
  tmp="$(mktemp)"
  printf "Approved %s %s\n" "$USER_NAME" "$DATE_STR" > "$tmp"
  cat -- "$f" >> "$tmp"
  mv -- "$tmp" "$f"
done
