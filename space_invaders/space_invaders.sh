#!/bin/bash

# Space Invaders in Bash with improved performance

# Terminal setup
tput civis   # Hide cursor
tput smcup   # Save screen
trap 'tput cnorm; tput rmcup; exit 0' EXIT

# Game area
GAME_WIDTH=60
GAME_HEIGHT=30

# Player
PLAYER_SHIP=(
    "   ▲   "
    "  ███  "
    " ▀███▀ "
)
PLAYER_WIDTH=7
PLAYER_HEIGHT=3
PLAYER_X=$((GAME_WIDTH / 2 - PLAYER_WIDTH / 2))
PLAYER_Y=$((GAME_HEIGHT - PLAYER_HEIGHT))

# Enemies
ENEMY_SHIP=(
    " ▄ ▄ "
    "▄███▄"
    " ▀ ▀ "
)
ENEMY_WIDTH=5
ENEMY_HEIGHT=3
NUM_ENEMIES=5
declare -A ENEMIES

# Bullet
BULLET="│"
BULLET_X=-1
BULLET_Y=-1

# Score
SCORE=0

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Game state
declare -A GAME_STATE
declare -A PREV_STATE

# Initialize enemies
init_enemies() {
    for ((i=0; i<NUM_ENEMIES; i++)); do
        ENEMIES[$i,0]=$((RANDOM % (GAME_WIDTH - ENEMY_WIDTH) + 1))
        ENEMIES[$i,1]=$((RANDOM % 5 + 1))
    done
}

# Update game state
update_game_state() {
    for ((y=0; y<GAME_HEIGHT; y++)); do
        for ((x=0; x<GAME_WIDTH; x++)); do
            GAME_STATE[$y,$x]=" "
        done
    done

    # Update player
    for ((y=0; y<PLAYER_HEIGHT; y++)); do
        for ((x=0; x<PLAYER_WIDTH; x++)); do
            GAME_STATE[$((PLAYER_Y + y)),$((PLAYER_X + x))]="${GREEN}${PLAYER_SHIP[y]:x:1}${RESET}"
        done
    done

    # Update bullet
    if [ $BULLET_Y -ge 0 ] && [ $BULLET_Y -lt $GAME_HEIGHT ]; then
        GAME_STATE[$BULLET_Y,$BULLET_X]="${CYAN}$BULLET${RESET}"
    fi

    # Update enemies
    for ((i=0; i<NUM_ENEMIES; i++)); do
        local enemy_x=${ENEMIES[$i,0]}
        local enemy_y=${ENEMIES[$i,1]}
        for ((y=0; y<ENEMY_HEIGHT; y++)); do
            for ((x=0; x<ENEMY_WIDTH; x++)); do
                if [ $((enemy_y + y)) -lt $GAME_HEIGHT ]; then
                    GAME_STATE[$((enemy_y + y)),$((enemy_x + x))]="${RED}${ENEMY_SHIP[y]:x:1}${RESET}"
                fi
            done
        done
    done
}

# Draw changes
draw_changes() {
    for ((y=0; y<GAME_HEIGHT; y++)); do
        for ((x=0; x<GAME_WIDTH; x++)); do
            if [ "${GAME_STATE[$y,$x]}" != "${PREV_STATE[$y,$x]}" ]; then
                tput cup $((y + 2)) $x
                echo -ne "${GAME_STATE[$y,$x]}"
                PREV_STATE[$y,$x]="${GAME_STATE[$y,$x]}"
            fi
        done
    done
}

# Move player
move_player() {
    case $1 in
        'left') [ $PLAYER_X -gt 0 ] && ((PLAYER_X--)) ;;
        'right') [ $PLAYER_X -lt $((GAME_WIDTH - PLAYER_WIDTH)) ] && ((PLAYER_X++)) ;;
    esac
}

# Fire bullet
fire_bullet() {
    if [ $BULLET_Y -eq -1 ]; then
        BULLET_X=$((PLAYER_X + PLAYER_WIDTH / 2))
        BULLET_Y=$((PLAYER_Y - 1))
    fi
}

# Move bullet
move_bullet() {
    if [ $BULLET_Y -gt -1 ]; then
        ((BULLET_Y--))
        if [ $BULLET_Y -eq -1 ]; then
            BULLET_X=-1
        fi
    fi
}

# Move enemies
move_enemies() {
    for ((i=0; i<NUM_ENEMIES; i++)); do
        if [ $((RANDOM % 5)) -eq 0 ]; then
            if [ $((RANDOM % 2)) -eq 0 ]; then
                [ ${ENEMIES[$i,0]} -gt 0 ] && ((ENEMIES[$i,0]--))
            else
                [ ${ENEMIES[$i,0]} -lt $((GAME_WIDTH - ENEMY_WIDTH)) ] && ((ENEMIES[$i,0]++))
            fi
        fi
        ((ENEMIES[$i,1]++))
        if [ ${ENEMIES[$i,1]} -ge $GAME_HEIGHT ]; then
            ENEMIES[$i,0]=$((RANDOM % (GAME_WIDTH - ENEMY_WIDTH) + 1))
            ENEMIES[$i,1]=0
        fi
    done
}

# Check collisions
check_collisions() {
    for ((i=0; i<NUM_ENEMIES; i++)); do
        if [ $BULLET_X -ge ${ENEMIES[$i,0]} ] && [ $BULLET_X -lt $((${ENEMIES[$i,0]} + ENEMY_WIDTH)) ] && \
           [ $BULLET_Y -ge ${ENEMIES[$i,1]} ] && [ $BULLET_Y -lt $((${ENEMIES[$i,1]} + ENEMY_HEIGHT)) ]; then
            ENEMIES[$i,0]=$((RANDOM % (GAME_WIDTH - ENEMY_WIDTH) + 1))
            ENEMIES[$i,1]=0
            BULLET_Y=-1
            BULLET_X=-1
            ((SCORE++))
        fi
        if [ ${ENEMIES[$i,1]} -ge $PLAYER_Y ]; then
            return 1
        fi
    done
    return 0
}

# Read a single keypress (non-blocking)
read_key() {
    if read -t 0.1 -n 1 key; then
        if [[ $key = $'\x1b' ]]; then
            read -t 0.1 -n 2 key
            case $key in
                '[A') echo "up" ;;
                '[B') echo "down" ;;
                '[C') echo "right" ;;
                '[D') echo "left" ;;
            esac
        else
            echo "$key"
        fi
    fi
}

# Main game loop
main() {
    init_enemies
    tput clear

    # Draw initial screen
    echo -e "${YELLOW}Score: $SCORE${RESET}"
    echo -e "${CYAN}Use ← → to move, ↑ to fire, q to quit${RESET}"

    while true; do
        key=$(read_key)
        case $key in
            'left'|'right') move_player $key ;;
            'up') fire_bullet ;;
            'q') break ;;
        esac

        move_bullet
        move_enemies
        if ! check_collisions; then
            tput cup $((GAME_HEIGHT + 2)) 0
            echo -e "${RED}Game Over! Your score: $SCORE${RESET}"
            break
        fi

        update_game_state
        draw_changes

        # Update score
        tput cup 0 7
        echo -ne "${YELLOW}$SCORE${RESET}"

        sleep 0.05
    done
}

# Start the game
main

# Show cursor and restore screen
tput cnorm
tput rmcup
