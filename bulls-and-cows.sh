set -u

if [[ ${BASH_VERSINFO[0]} -lt 5 || ( ${BASH_VERSINFO[0]} -eq 5 && ${BASH_VERSINFO[1]} -lt 2 ) ]]; then
  echo "Требуется bash 5.2 или выше. Текущая версия: ${BASH_VERSION}" >&2
  exit 2
fi

trap 'echo -e "\nЧтобы завершить игру, введите символ \"q\" или \"Q\". Продолжаем...";' INT

cat <<'BANNER'
********************************************************************************
* Я загадал 4-значное число с неповторяющимися цифрами. На каждом ходу делайте *
* попытку отгадать загаданное число. Попытка - это 4-значное число с           *
* неповторяющимися цифрами.                                                    *
********************************************************************************
BANNER

gen_secret() {
  local s="" d used="::::::::::"
  while (( ${#s} < 4 )); do
    d=$((RANDOM % 10))
    if (( ${#s} == 0 && d == 0 )); then
      continue
    fi
    if [[ ${used:d:1} != "#" ]]; then
      s+="$d"
      used="${used:0:d}#${used:d+1}"
    fi
  done
  echo "$s"
}

secret="$(gen_secret)"

is_valid_guess() {
  local g="$1"
  [[ "$g" =~ ^[1-9][0-9]{3}$ ]] || return 1
  local i j
  for ((i=0;i<4;i++)); do
    for ((j=i+1;j<4;j++)); do
      [[ ${g:i:1} != ${g:j:1} ]] || return 1
    done
  done
  return 0
}

count_cows_bulls() {
  local g="$1" s="$2"
  local cows=0 bulls=0 i j
  for ((i=0;i<4;i++)); do
    if [[ ${g:i:1} == ${s:i:1} ]]; then
      ((bulls++))
    else
      for ((j=0;j<4;j++)); do
        if (( i != j )) && [[ ${g:i:1} == ${s:j:1} ]]; then
          ((cows++))
          break
        fi
      done
    fi
  done
  echo "$cows $bulls"
}

declare -a hist_guess=()
declare -a hist_cows=()
declare -a hist_bulls=()

attempt=0

while true; do
  read -rp "Попытка $((attempt+1)): " guess

  if [[ "$guess" == "q" || "$guess" == "Q" ]]; then
    exit 1
  fi

  if ! is_valid_guess "$guess"; then
    echo "Ошибка ввода. Требуется 4-значное число без повторяющихся цифр (первая цифра не 0), или 'q'/'Q' для выхода."
    continue
  fi

  ((attempt++))
  read -r cows bulls < <(count_cows_bulls "$guess" "$secret")

  echo "Коров - $cows Быков - $bulls"
  hist_guess+=("$guess")
  hist_cows+=("$cows")
  hist_bulls+=("$bulls")

  echo -e "\nИстория ходов:"
  for ((i=0;i<${#hist_guess[@]};i++)); do
    echo "$((i+1)). ${hist_guess[$i]} (Коров - ${hist_cows[$i]} Быков - ${hist_bulls[$i]})"
  done
  echo

  if (( bulls == 4 )); then
    echo "Вы угадали загаданное число: $secret"
    exit 0
  fi
done
