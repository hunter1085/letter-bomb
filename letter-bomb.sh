#!/bin/bash

#get size of console
CURRENT_DIR=$(cd `dirname $0`;pwd)
COMPONENT_NAME=$(basename $0|cut -d'.' -f1)
LOG_FILE=$CURRENT_DIR/$COMPONENT_NAME.log
echo "">$LOG_FILE
HEIGHT=$(stty size | awk '{print $1}')
WIDTH=$(stty size | awk '{print $2}')
echo "HEIGHT=$HEIGHT" >>$LOG_FILE


START="false"
ALIVE="true"
SPACE_PRESS_CNT=0
LETTERS=("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" \
         "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" \
         "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" \
         "~" "@" "#" "$" "%" "^" "&" "*" "(" ")" "-" "+" "_" "=" ";" ":" "<" ">" "," "." "[" "]" "{" "}" "|" '\' '"' )
LETTER_CNT=${#LETTERS[@]}
BOMB=()

onExit(){
    echo -e "\x1b[0;0H\x1b[2J\x1b[?25h\x1b[0m" #recover the cursor
}
onPause(){
    if [ "$START" == "true" ]; then
        START="false"
    else
        START="true"
    fi
    if [ $SPACE_PRESS_CNT -eq 0 ];then
        ((SPACE_PRESS_CNT++))
        echo -e "\x1b[0;0H\x1b[2J\x1b[?25l"
    fi
}
printMenu(){
    echo -e "\x1b[32mPlay\x1b[0m        : Input the letter to remove the bomb!"
    echo -e "\x1b[32mControl\x1b[0m     :"
    echo -e "    [\x1b[35mCtrl + z\x1b[0m] : \x1b[5mstart/pause\x1b[0m"
    echo -e "    [\x1b[35mCtrl + c\x1b[0m]   : quit"
}

generateBomb(){
    local x=$(( (RANDOM % WIDTH) + 1 ))
    local y=1
    local index=$(( (RANDOM % LETTER_CNT) ))
    local letter=${LETTERS[$index]}
    local color=$(( (RANDOM % 7) + 31 ))
    local bomb="$x:$y:$letter:$color"
    BOMB=(${BOMB[@]} $bomb)
}
removeBomb(){
    local cadidate=$1
    local found="false"
    for ((i=0;i<${#BOMB[@]};i++)); do
        local bomb=${BOMB[$i]}
        local info=(${bomb//:/ })
        if [ "${info[2]}" == "$cadidate" ];then  #found
            found="true"
            break
        fi
    done
    if [ "$found" == "true" ];then
        unset BOMB[$i]
        BOMB=(${BOMB[@]})  #reset the array
    fi
}
moveBomb(){
    local bomb
    for((i=0;i<${#BOMB[@]};i++));do
        local bomb=${BOMB[$i]}
        local info=(${bomb//:/ })
        local x=${info[0]}
        local y=$(((${info[1]}+1)))
        local letter=${info[2]}
        local color=${info[3]}
        BOMB[$i]="$x:$y:$letter:$color"
    done
}
printBomb(){
    echo -e "\x1b[0;0H\x1b[2J\x1b[?25l" #clear the screen and hide the cursor
    for((i=0;i<${#BOMB[@]};i++));do
        local bomb=${BOMB[$i]}
        local info=(${bomb//:/ })
        local x=${info[0]}
        local y=${info[1]}
        local letter=${info[2]}
        local color=${info[3]}
        if [ "$ALIVE" == "false" ];then
            if [ $i -eq 0 ];then
                echo -e "\x1b["$y";"$x"H\x1b[5m\x1b["$color"m$letter\x1b[0m"
            else
                echo -e "\x1b["$y";"$x"H\x1b["$color"m$letter"
            fi
        else
            echo -e "\x1b["$y";"$x"H\x1b["$color"m$letter"
        fi
    done
#    echo "printBomb----BOMB=${BOMB[@]}" >>$LOG_FILE
}
isBombLanded(){
    local landed="false"
    if [ -n "$BOMB" ];then
        local bomb=${BOMB[0]}
        local info=(${bomb//:/ })
        local y=${info[1]}
        if [ $y -ge $HEIGHT ];then
            landed="true"
        fi
    fi
    if [ "$landed" == "true" ];then
        ALIVE="false"
        printBomb
    fi
}

trap 'onExit; exit' EXIT
trap 'onPause' SIGTSTP
echo -e "\x1b[0;0H\x1b[2J\x1b[?25l"  #clear the screen and hide the cursor
printMenu

step=0
while :; do
    read -s -t 0.5 -n 1  key_in
    ((step++))


    if [ $SPACE_PRESS_CNT -ne 0 ] && [ "$START" == "true" ] && [ "$ALIVE" == "true" ];then
        removeBomb "$key_in"
        if [ $(((step % 4 ))) -eq 0 ];then
            generateBomb
        fi
        if [ $(((step % 2 ))) -eq 0 ];then
            moveBomb
            printBomb
        fi
    fi

    if [ $step -eq 16 ];then
        step=0
    fi
    isBombLanded
done
