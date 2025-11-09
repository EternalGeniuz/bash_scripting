GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

step=0
hits=0
misses=0
numbers=()
results=()

while true; do
    ((step++))
    echo "Раунд: $step"
    read -p "Введите цифру от 0 до 9 (q - выход): " input

    if [[ "$input" == "q" ]]; then
        echo "Игра окончена!"
        break
    fi

    if ! [[ "$input" =~ ^[0-9]$ ]]; then
        echo "Ошибка: введите цифру от 0 до 9 или q для выхода"
        ((step--))
        continue
    fi

    mynum=$((RANDOM % 10))

    if [[ "$input" -eq "$mynum" ]]; then
        echo -e "${GREEN}Угадал! Моя цифра: $mynum ${RESET}"
        ((hits++))
        result=1
    else
        echo -e "${RED}Промах! Моя цифра: $mynum${RESET}"
        ((misses++))
        result=0
    fi

    numbers+=("$mynum")
    results+=("$result")

    if [[ ${#numbers[@]} -gt 10 ]]; then
        numbers=("${numbers[@]: -10}")
        results=("${results[@]: -10}")
    fi

    total=$((hits + misses))
    if [[ $total -gt 0 ]]; then
        hit_percent=$((100 * hits / total))
        miss_percent=$((100 - hit_percent))
    else
        hit_percent=0
        miss_percent=0
    fi
    echo -e "Попаданий: ${hit_percent}% Промахов: ${miss_percent}%"

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
