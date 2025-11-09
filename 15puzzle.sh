#объявляю массив для хранения борда пятнашек

declare -a board

#отрисовываю борд для игры, в котором вывожу последовательно 4 ячейки массива из каждой строки
print_board() {
  echo "+-------------------+"
  for r in {0..3}; do
    printf "| %2s | %2s | %2s | %2s |\n" \
      "$(cell_to_str $((4*r+0)))" \
      "$(cell_to_str $((4*r+1)))" \
      "$(cell_to_str $((4*r+2)))" \
      "$(cell_to_str $((4*r+3)))"
    if (( r < 3 )); then
      echo "|-------------------|"
    fi
  done
  echo "+-------------------+"
}

#функция, которой перевожу значения массива в символ
cell_to_str() {
  local v=${board[$1]}
  [[ $v -eq 0 ]] && echo " " || echo "$v"
}

#функция для нахождения позиции в массиве
find_index() {
  local v=$1
  for i in "${!board[@]}"; do
    if [[ ${board[$i]} -eq $v ]]; then
      echo "$i"; return 0
    fi
  done
  echo -1; return 1
}

#функция для проверки победы, которая пробегается по элементам массива и проверяет, что элементы с индексами 0-14 содержат значения 1-15, а 15 индекс содержит 0
is_solved() {
  for i in {0..14}; do
    [[ ${board[$i]} -eq $((i+1)) ]] || return 1
  done
  [[ ${board[15]} -eq 0 ]]
}

#функция для поиска плиток, которые можно двигать. проверяет, есть ли клетка слева, справа, сверху, снизу и возвращает значения соседних плиток, которые можно двигать
neighbors_of_blank() {
  local bi
  bi=$(find_index 0)
  local r=$((bi/4))
  local c=$((bi%4))
  local res=() idx
  if (( c > 0 )); then idx=$((bi-1)); res+=("${board[$idx]}"); fi
  if (( c < 3 )); then idx=$((bi+1)); res+=("${board[$idx]}"); fi
  if (( r > 0 )); then idx=$((bi-4)); res+=("${board[$idx]}"); fi
  if (( r < 3 )); then idx=$((bi+4)); res+=("${board[$idx]}"); fi
  echo "${res[@]}"
}

#функция, которая реализует игру, попытка сделать ход
#Алгоритм:
#1. Ищем позицию пустой клетки 2. Ищем позицию плитки 3. Вычисляем их разницу по столбцам 4. Если |dr| + |dc| == 1, то клетки соседние и мы можем поменять их местами
try_move() {
  local val=$1
  local bi ti
  bi=$(find_index 0)
  ti=$(find_index "$val")
  [[ $ti -ge 0 ]] || return 1

  local br=$((bi/4)) bc=$((bi%4))
  local tr=$((ti/4)) tc=$((ti%4))
  local dr=$(( br - tr ))
  local dc=$(( bc - tc ))
  (( dr<0 )) && dr=$(( -dr ))
  (( dc<0 )) && dc=$(( -dc ))

  if (( dr + dc == 1 )); then
    board[$bi]=${board[$ti]}
    board[$ti]=0
    return 0
  fi
  return 1
}

#функция, которая считает количество инверсий
count_inversions() {
  local inv=0 i j vi vj
  for ((i=0;i<16;i++)); do
    vi=${board[$i]}
    (( vi==0 )) && continue
    for ((j=i+1;j<16;j++)); do
      vj=${board[$j]}
      (( vj==0 )) && continue
      (( vi>vj )) && ((inv++))
    done
  done
  echo "$inv"
}

#функция, которая находит, на какой строке снизу стоит пустая клетка
blank_row_from_bottom() {
  local bi=$(find_index 0)
  local row_top=$((bi/4))
  echo $((4 - row_top))
}

#вычисляет разрешимость и возможность победы с помощью 2х функций выше
is_solvable() {
  local inv=$(count_inversions)
  local rb=$(blank_row_from_bottom)
  local sum=$(( (inv + rb) % 2 ))
  [[ $sum -eq 1 ]]
}

#функция, которая перемешивает числа на доске для начала игры, но проверяет разрешимость такой комбинации и проверяет не была ли случайно доска перемешана до решенной
shuffle_board() {
  board=()
  for ((i=1;i<=15;i++)); do board+=("$i"); done
  board+=(0)

  while true; do
    for ((i=15;i>0;i--)); do
      j=$((RANDOM % (i+1)))
      tmp=${board[$i]}
      board[$i]=${board[$j]}
      board[$j]=$tmp
    done
    is_solvable && ! is_solved && break
  done
}

#перемешиваем борд
shuffle_board

#завожу переменную для подсчета ходов
moves=0

#основной цикл самой игры. Каждый шаг печатается номер хода, игровое поле и читается ввод
while true; do
  echo "Ход № $((moves+1))"
  echo
  print_board
  echo
  read -rp "Ваш ход (q - выход): " inp

#если юзер ввел q или Q - выход из игры
  if [[ "$inp" == "q" || "$inp" == "Q" ]]; then
    echo "Выход из игры."
    exit 0
  fi
#если юзер ввел нечисловое значение в пределах 1-15 - предупреждение (также проверяю регуляркой)
  if ! [[ "$inp" =~ ^([1-9]|1[0-5])$ ]]; then
    echo
    echo "Неверный ввод! Введите число 1..15, соседнее с пустой клеткой, или q для выхода."
    echo
    continue
  fi

#проверка возможности хода
  if try_move "$inp"; then
    ((moves++))

#проверка выиграл ли юзер
    if is_solved; then
      echo
      echo "Вы собрали головоломку за $moves ходов."
      echo
      print_board
      exit 0
    fi
    echo
  else
#если юзер делает невозможный ход - выводим предупреждение. Также выводит номера костяшек, которые можно передвинуть фактически
    opts=( $(neighbors_of_blank) )
    filtered=()
    for v in "${opts[@]}"; do
      (( v!=0 )) && filtered+=("$v")
    done
    echo
    echo "Неверный ход!"
    echo "Невозможно костяшку $inp передвинуть на пустую ячейку."
    if ((${#filtered[@]})); then
      IFS=', ' read -r -a dummy <<< "${filtered[*]}"
      echo -n "Можно выбрать: "
      for i in "${!filtered[@]}"; do
        if (( i>0 )); then printf ", "; fi
        printf "%s" "${filtered[$i]}"
      done
      echo
    fi
    echo
  fi
done
