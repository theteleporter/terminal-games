#!/bin/bash

# Battleship Game

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Game constants
BOARD_SIZE=10
SHIP_TYPES=("Carrier:5" "Battleship:4" "Cruiser:3" "Submarine:3" "Destroyer:2")

# Initialize boards
init_board() {
    for ((i=0; i<BOARD_SIZE; i++)); do
        for ((j=0; j<BOARD_SIZE; j++)); do
            PLAYER_BOARD[$i,$j]="~"
            COMPUTER_BOARD[$i,$j]="~"
            PLAYER_GUESS_BOARD[$i,$j]="~"
        done
    done
}

# Display the game board
display_board() {
    local board=("$@")
    echo -e "${YELLOW}   A B C D E F G H I J${RESET}"
    for ((i=0; i<BOARD_SIZE; i++)); do
        printf "${YELLOW}%2d${RESET} " $((i+1))
        for ((j=0; j<BOARD_SIZE; j++)); do
            cell=${board[$i,$j]}
            case $cell in
                "~") echo -ne "${BLUE}~ ${RESET}" ;;
                "O") echo -ne "${GREEN}O ${RESET}" ;;
                "X") echo -ne "${RED}X ${RESET}" ;;
                "*") echo -ne "${YELLOW}* ${RESET}" ;;
            esac
        done
        echo
    done
}

# Place ships on the board
place_ships() {
    local board_type=$1
    for ship in "${SHIP_TYPES[@]}"; do
        IFS=':' read -r name length <<< "$ship"
        while true; do
            if [[ $board_type == "player" ]]; then
                echo -e "${CYAN}Place your $name (length: $length)${RESET}"
                read -p "Enter start position (e.g., A1): " start_pos
                read -p "Enter orientation (H/V): " orientation
                row=$((${start_pos:1} - 1))
                col=$(echo ${start_pos:0:1} | tr 'A-J' '0-9')
            else
                row=$((RANDOM % BOARD_SIZE))
                col=$((RANDOM % BOARD_SIZE))
                orientation=$((RANDOM % 2))
                [[ $orientation -eq 0 ]] && orientation="H" || orientation="V"
            fi

            if validate_placement $row $col $length $orientation $board_type; then
                place_ship $row $col $length $orientation $board_type
                break
            elif [[ $board_type == "player" ]]; then
                echo -e "${RED}Invalid placement. Try again.${RESET}"
            fi
        done
    done
}

# Validate ship placement
validate_placement() {
    local row=$1 col=$2 length=$3 orientation=$4 board_type=$5
    local board_var="${board_type^^}_BOARD"

    for ((i=0; i<length; i++)); do
        if [[ $orientation == "H" ]]; then
            [[ $((col+i)) -ge $BOARD_SIZE ]] && return 1
            [[ ${!board_var[$row,$((col+i))]} != "~" ]] && return 1
        else
            [[ $((row+i)) -ge $BOARD_SIZE ]] && return 1
            [[ ${!board_var[$((row+i)),$col]} != "~" ]] && return 1
        fi
    done
    return 0
}

# Place a ship on the board
place_ship() {
    local row=$1 col=$2 length=$3 orientation=$4 board_type=$5
    local board_var="${board_type^^}_BOARD"

    for ((i=0; i<length; i++)); do
        if [[ $orientation == "H" ]]; then
            eval "${board_var}[$row,$((col+i))]='O'"
        else
            eval "${board_var}[$((row+i)),$col]='O'"
        fi
    done
}

# Player's turn
player_turn() {
    while true; do
        echo -e "${CYAN}Your turn to attack!${RESET}"
        read -p "Enter target position (e.g., A1): " target
        row=$((${target:1} - 1))
        col=$(echo ${target:0:1} | tr 'A-J' '0-9')

        if [[ $row -lt 0 || $row -ge $BOARD_SIZE || $col -lt 0 || $col -ge $BOARD_SIZE ]]; then
            echo -e "${RED}Invalid target. Try again.${RESET}"
            continue
        fi

        if [[ ${PLAYER_GUESS_BOARD[$row,$col]} != "~" ]]; then
            echo -e "${YELLOW}You've already attacked this position. Try again.${RESET}"
            continue
        fi

        if [[ ${COMPUTER_BOARD[$row,$col]} == "O" ]]; then
            PLAYER_GUESS_BOARD[$row,$col]="X"
            COMPUTER_BOARD[$row,$col]="X"
            echo -e "${GREEN}Hit!${RESET}"
        else
            PLAYER_GUESS_BOARD[$row,$col]="*"
            echo -e "${RED}Miss!${RESET}"
        fi
        break
    done
}

# Computer's turn
computer_turn() {
    echo -e "${MAGENTA}Computer's turn to attack!${RESET}"
    while true; do
        row=$((RANDOM % BOARD_SIZE))
        col=$((RANDOM % BOARD_SIZE))

        if [[ ${PLAYER_BOARD[$row,$col]} == "~" || ${PLAYER_BOARD[$row,$col]} == "O" ]]; then
            if [[ ${PLAYER_BOARD[$row,$col]} == "O" ]]; then
                PLAYER_BOARD[$row,$col]="X"
                echo -e "${RED}Computer hit your ship at $((row+1))$(echo $col | tr '0-9' 'A-J')!${RESET}"
            else
                PLAYER_BOARD[$row,$col]="*"
                echo -e "${GREEN}Computer missed at $((row+1))$(echo $col | tr '0-9' 'A-J').${RESET}"
            fi
            break
        fi
    done
}

# Check if all ships are sunk
check_game_over() {
    local board=("$@")
    for ((i=0; i<BOARD_SIZE; i++)); do
        for ((j=0; j<BOARD_SIZE; j++)); do
            [[ ${board[$i,$j]} == "O" ]] && return 1
        done
    done
    return 0
}

# Main game loop
main() {
    echo -e "${CYAN}Welcome to Battleship!${RESET}"
    init_board

    echo -e "${YELLOW}Placing your ships...${RESET}"
    place_ships "player"
    echo -e "${YELLOW}Computer is placing its ships...${RESET}"
    place_ships "computer"

    while true; do
        echo -e "\n${BLUE}Your board:${RESET}"
        display_board "${PLAYER_BOARD[@]}"
        echo -e "\n${RED}Your guesses:${RESET}"
        display_board "${PLAYER_GUESS_BOARD[@]}"

        player_turn
        if check_game_over "${COMPUTER_BOARD[@]}"; then
            echo -e "${GREEN}Congratulations! You've sunk all enemy ships!${RESET}"
            break
        fi

        computer_turn
        if check_game_over "${PLAYER_BOARD[@]}"; then
            echo -e "${RED}Game Over! The computer has sunk all your ships!${RESET}"
            break
        fi
    done

    echo -e "\n${YELLOW}Final boards:${RESET}"
    echo -e "\n${BLUE}Your board:${RESET}"
    display_board "${PLAYER_BOARD[@]}"
    echo -e "\n${RED}Computer's board:${RESET}"
    display_board "${COMPUTER_BOARD[@]}"
}

# Start the game
main
