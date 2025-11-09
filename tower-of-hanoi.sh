set -u

if [[ ${BASH_VERSINFO[0]} -lt 5 || ( ${BASH_VERSINFO[0]} -eq 5 && ${BASH_VERSINFO[1]} -lt 2 ) ]]; then
  echo "Требуется bash 5.2 или выше. Текущая версия: ${BASH_VERSION}" >&2
  exit 2
fi

trap 'echo -e "\nЧтобы завершить сценарий, введите символ \"q\" или \"Q\". Продолжаем...";' INT

A=(8 7 6 5 4 3 2 1)
B=()
C=()

print_stacks() {
  local rows=8
  for ((row=0; row<rows; row++)); do
    printf "|%2s|  |%2s|  |%2s|\n" \
      "$(val_at_height A "$row" "$rows")" \
      "$(val_at_height B "$row" "$rows")" \
      "$(val_at_height C "$row" "$rows")"
  done
  echo "+-+  +-+  +-+"
  echo " A    B    C"
}

val_at_height() {
  local name="$1" row="$2" rows="$3"
  declare -n stk="$name"
  local n=${#stk[@]}
  local empty_rows=$((rows - n))
  if (( row < empty_rows )); then
    printf " "
    return
  fi

  local idx=$(( (rows - 1 - row) ))
  printf "%s" "${stk[$idx]}"
}


move_disk() {
  local from="$1" to="$2"
  declare -n SF="$from" ST="$to"

  if ((${#SF[@]} == 0)); then
    echo "Такое перемещение запрещено! Источник пуст."
    return 1
  fi

  local disk="${SF[-1]}"

  if ((${#ST[@]} > 0)); then
    local top="${ST[-1]}"
    if (( disk > top )); then
      echo "Такое перемещение запрещено!"
      return 1
    fi
  fi

  unset 'SF[-1]'
  SF=("${SF[@]}")
  ST+=("$disk")
  return 0
}

is_goal() {
  declare -n S="$1"
  [[ ${#S[@]} -eq 8 ]] || return 1
  local expect=(8 7 6 5 4 3 2 1)
  for i in {0..7}; do
    [[ "${S[$i]}" -eq "${expect[$i]}" ]] || return 1
  done
  return 0
}

normalize_stack() {
  local s="${1^^}"
  case "$s" in
    A|B|C) echo "$s"; return 0 ;;
    *)     echo "";  return 1 ;;
  esac
}

step=1

while true; do
  print_stacks
  read -rp "Ход № $step (откуда, куда): " input

  if [[ "$input" =~ ^[qQ]$ ]]; then
    exit 1
  fi

  letters="$(tr -cd '[:alpha:]' <<<"$input" | tr '[:lower:]' '[:upper:]')"
  if (( ${#letters} != 2 )); then
    echo "Ошибка ввода. Укажите два имени стеков (A/B/C), например: ab, A c, bC; или q для выхода."
    continue
  fi

  from="$(normalize_stack "${letters:0:1}")" || true
  to="$(normalize_stack "${letters:1:1}")" || true
  if [[ -z "$from" || -z "$to" || "$from" == "$to" ]]; then
    echo "Ошибка ввода. Укажите два РАЗНЫХ корректных имени стеков (A/B/C)."
    continue
  fi

  if move_disk "$from" "$to"; then
    ((step++))

    if is_goal B || is_goal C; then
      echo
      echo "Вы победили за $((step-1)) ход(ов)."
      print_stacks
      exit 0
    fi
  else
    :
  fi

  echo
done
