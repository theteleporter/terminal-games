#!/bin/bash

# Prompt player for their name and preferred speed
echo -n "Enter your name: "
read PLAYER_NAME
echo -n "Enter ball speed (1-20, where 1 is fastest): "
read SPEED
if [[ ! $SPEED =~ ^[0-9]+$ || $SPEED -lt 1 || $SPEED -gt 20 ]]; then
    SPEED=10  # Default speed if invalid input
fi
BALL_DELAY=$(awk "BEGIN {print $SPEED / 1000}")  # Convert speed to delay time

# Get terminal dimensions
WIDTH=$(tput cols)
HEIGHT=$(tput lines)

# Adjust HEIGHT to fit the game elements
HEIGHT=$((HEIGHT - 2))

# Game settings
PADDLE_WIDTH=6
BALL_POS_X=$((WIDTH / 2))
BALL_POS_Y=$((HEIGHT / 2))
BALL_DIR_X=1
BALL_DIR_Y=-1
PLAYER_PADDLE_X=$((WIDTH / 2 - PADDLE_WIDTH / 2))
COMPUTER_PADDLE_X=$((WIDTH / 2 - PADDLE_WIDTH / 2))
PLAYER_SCORE=0
COMPUTER_SCORE=0

# Function to draw the game field
draw_field() {
    tput cup 0 0
    for ((y=0; y<HEIGHT; y++)); do
        for ((x=0; x<WIDTH; x++)); do
            if [[ $y -eq 0 || $y -eq $((HEIGHT - 1)) ]]; then
                echo -n "━"
            elif [[ $x -eq $BALL_POS_X && $y -eq $BALL_POS_Y ]]; then
                echo -n "●"
            elif [[ $y -eq $((HEIGHT - 2)) && $x -ge $PLAYER_PADDLE_X && $x -lt $((PLAYER_PADDLE_X + PADDLE_WIDTH)) ]]; then
                echo -n "⣿"
            elif [[ $y -eq 1 && $x -ge $COMPUTER_PADDLE_X && $x -lt $((COMPUTER_PADDLE_X + PADDLE_WIDTH)) ]]; then
                echo -n "⣿"
            else
                echo -n " "
            fi
        done
        echo
    done
    echo "$PLAYER_NAME's Score: $PLAYER_SCORE | Computer Score: $COMPUTER_SCORE"
}

# Function to move the ball
move_ball() {
    BALL_POS_X=$((BALL_POS_X + BALL_DIR_X))
    BALL_POS_Y=$((BALL_POS_Y + BALL_DIR_Y))

    # Check for collision with left and right walls
    if [[ $BALL_POS_X -le 0 || $BALL_POS_X -ge $((WIDTH - 1)) ]]; then
        BALL_DIR_X=$((-BALL_DIR_X))
    fi

    # Check for collision with paddles
    if [[ $BALL_POS_Y -eq $((HEIGHT - 2)) && $BALL_POS_X -ge $PLAYER_PADDLE_X && $BALL_POS_X -lt $((PLAYER_PADDLE_X + PADDLE_WIDTH)) ]]; then
        BALL_DIR_Y=$((-BALL_DIR_Y))
    elif [[ $BALL_POS_Y -eq 1 && $BALL_POS_X -ge $COMPUTER_PADDLE_X && $BALL_POS_X -lt $((COMPUTER_PADDLE_X + PADDLE_WIDTH)) ]]; then
        BALL_DIR_Y=$((-BALL_DIR_Y))
    fi

    # Check for scoring
    if [[ $BALL_POS_Y -le 0 ]]; then
        PLAYER_SCORE=$((PLAYER_SCORE + 1))
        reset_ball
    elif [[ $BALL_POS_Y -ge $((HEIGHT - 1)) ]]; then
        COMPUTER_SCORE=$((COMPUTER_SCORE + 1))
        reset_ball
    fi
}

# Reset ball position
reset_ball() {
    BALL_POS_X=$((WIDTH / 2))
    BALL_POS_Y=$((HEIGHT / 2))
    BALL_DIR_X=$((RANDOM % 2 == 0 ? 1 : -1))
    BALL_DIR_Y=$((RANDOM % 2 == 0 ? 1 : -1))
}

# Function to move the computer paddle
move_computer_paddle() {
    # Only move if the ball is moving toward the computer
    if [[ $BALL_DIR_Y -lt 0 ]]; then
        # Computer paddle attempts to align with the ball
        if [[ $BALL_POS_X -gt $((COMPUTER_PADDLE_X + PADDLE_WIDTH / 2)) ]]; then
            COMPUTER_PADDLE_X=$((COMPUTER_PADDLE_X + 1))  # Move right
        elif [[ $BALL_POS_X -lt $((COMPUTER_PADDLE_X + PADDLE_WIDTH / 2)) ]]; then
            COMPUTER_PADDLE_X=$((COMPUTER_PADDLE_X - 1))  # Move left
        fi

        # Ensure the computer paddle stays within the screen boundaries
        if [[ $COMPUTER_PADDLE_X -lt 0 ]]; then
            COMPUTER_PADDLE_X=0
        elif [[ $COMPUTER_PADDLE_X -gt $((WIDTH - PADDLE_WIDTH)) ]]; then
            COMPUTER_PADDLE_X=$((WIDTH - PADDLE_WIDTH))
        fi
    fi
}

# Function to handle player input
handle_input() {
    if [[ -n $INPUT ]]; then
        case $INPUT in
            $'\e[D') PLAYER_PADDLE_X=$((PLAYER_PADDLE_X - 2)) ;; # Left arrow
            $'\e[C') PLAYER_PADDLE_X=$((PLAYER_PADDLE_X + 2)) ;; # Right arrow
        esac
        INPUT=""
    fi

    # Ensure the player paddle stays within the screen boundaries
    if [[ $PLAYER_PADDLE_X -lt 0 ]]; then
        PLAYER_PADDLE_X=0
    elif [[ $PLAYER_PADDLE_X -gt $((WIDTH - PADDLE_WIDTH)) ]]; then
        PLAYER_PADDLE_X=$((WIDTH - PADDLE_WIDTH))
    fi
}

# Main game loop
stty -echo -icanon time 0 min 0
trap 'stty echo icanon; tput cnorm; exit' INT
tput civis
while true; do
    draw_field
    move_ball
    move_computer_paddle
    handle_input
    sleep $BALL_DELAY
    INPUT=$(head -c 3 /dev/stdin)
done
