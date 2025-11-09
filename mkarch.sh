set -euo pipefail

usage() {
  cat <<'USAGE'
Использование:
  mkarch -d dir_path -n name

Обязательные параметры:
  -d dir_path   Путь к каталогу, содержимое которого упаковать
  -n name       Имя создаваемого самораспаковывающегося скрипта

После генерации:
  ./name            — распакует в текущий каталог
  ./name -o /tmp    — распакует в /tmp
USAGE
  exit 1
}

DIR=""
NAME=""
while getopts ":d:n:h" opt; do
  case "$opt" in
    d) DIR="$OPTARG" ;;
    n) NAME="$OPTARG" ;;
    h) usage ;;
    \?) echo "Неизвестная опция: -$OPTARG" >&2; usage ;;
    :) echo "Опции -$OPTARG требуется аргумент" >&2; usage ;;
  esac
done

if [[ -z "$DIR" || -z "$NAME" ]]; then
  echo "Нужно указать -d и -n" >&2
  usage
fi
if [[ ! -d "$DIR" ]]; then
  echo "Каталог не найден: $DIR" >&2
  exit 2
fi

for cmd in tar gzip awk tail chmod mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Требуется утилита: $cmd" >&2; exit 3; }
done

TMPARCH="$(mktemp -t mkarch.XXXXXX.tar.gz)"
tar -C "$DIR" -czf "$TMPARCH" .

cat > "$NAME" <<'BASH_STUB'
set -euo pipefail

usage_unpack() {
  echo "Использование: $0 [-o unpackdir]" >&2
  exit 1
}

OUTDIR="."
while getopts ":o:h" opt; do
  case "$opt" in
    o) OUTDIR="$OPTARG" ;;
    h) usage_unpack ;;
    \?) echo "Неизвестная опция: -$OPTARG" >&2; usage_unpack ;;
    :) echo "Опции -$OPTARG требуется аргумент" >&2; usage_unpack ;;
  esac
done

true

mkdir -p "$OUTDIR"

MARK="__ARCHIVE_BELOW__"
LINE=$(awk -v m="$MARK" '$0==m {print NR; exit}' "$0" || true)
if [[ -z "${LINE:-}" ]]; then
  echo "Не найден маркер архива в $0" >&2
  exit 2
fi

tail -n +"$((LINE+1))" "$0" | tar -xz -C "$OUTDIR"
exit 0

__ARCHIVE_BELOW__
BASH_STUB

cat "$TMPARCH" >> "$NAME"

chmod a+x "$NAME"

rm -f "$TMPARCH"

echo "Готово: создан самораспаковывающийся скрипт '$NAME'"
echo "Примеры:"
echo "  ./$NAME             # распакует в текущий каталог"
echo "  ./$NAME -o /tmp     # распакует в /tmp"
