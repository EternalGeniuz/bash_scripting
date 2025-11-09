#задаю переменные для цвета

GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

#задаю переменные для раунда, попаданий и промахов для корректного отображения процентажа по попаданиям и промахам
step=0
hits=0
misses=0

#задаю 2 списка, которые будут фактически одинаковой размерности, для того, чтобы складывать цифры и результаты по ним
numbers=()
results=()

#база игры - это цикл while, в котором выводится число раунда и условия игры
while true; do
    ((step++))
    echo "Раунд: $step"
    read -p "Введите цифру от 0 до 9 (q - выход): " input

#если юзер вводит q - игра окончена
    if [[ "$input" == "q" ]]; then
        echo "Игра окончена!"
        break
    fi

#если юзер вводит что-то отличное от цифры (проверяю регуляркой), выводится предупреждение
    if ! [[ "$input" =~ ^[0-9]$ ]]; then
        echo "Ошибка: введите цифру от 0 до 9 или q для выхода"
        ((step--))
        continue
    fi

#случайно генерится цифра
    mynum=$((RANDOM % 10))

#проверка угадал юзер цифру или нет
    if [[ "$input" -eq "$mynum" ]]; then
        echo -e "${GREEN}Угадал! Моя цифра: $mynum ${RESET}"
        ((hits++))
        result=1
    else
        echo -e "${RED}Промах! Моя цифра: $mynum${RESET}"
        ((misses++))
        result=0
    fi

#складываем цифры из раундов и результаты по ним в списки одинакового размера
    numbers+=("$mynum")
    results+=("$result")

#храним максимум 10 цифр в списках результатов и цифр
    if [[ ${#numbers[@]} -gt 10 ]]; then
        numbers=("${numbers[@]: -10}")
        results=("${results[@]: -10}")
    fi

#считаю процентаж попаданий и промахов
    total=$((hits + misses))
    if [[ $total -gt 0 ]]; then
        hit_percent=$((100 * hits / total))
        miss_percent=$((100 - hit_percent))
    else
        hit_percent=0
        miss_percent=0
    fi
    echo -e "Попаданий: ${hit_percent}% Промахов: ${miss_percent}%"

#вывожу историю цифр. цвета применяю при поэлементном сравнении элементов двух списков
    echo -n "История цифр: "
    for i in "${!numbers[@]}"; do
        num="${numbers[$i]}"
        if [[ "${results[$i]}" -eq 1 ]]; then
            echo -ne "${GREEN}${num}${RESET} "
        else
            echo -ne "${RED}${num}${RESET} "
        fi
    done
    echo -e "\n"
done
