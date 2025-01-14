#!/bin/bash

# Wordlist path
WORDLIST="$HOME/games/data/wordlist.txt"
USER_DATA_FILE="$HOME/games/word_scramble/word_scramble_user_data.txt"

# Check if wordlist exists
if [[ ! -f "$WORDLIST" ]]; then
    echo "Wordlist not found at $WORDLIST. Please generate it first."
    exit 1
fi

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Function to save user data
save_user_data() {
    local user_name=$1
    local attempts=$2
    local score=$3

    # Check if user data file exists, if not, create it
    if [[ ! -f "$USER_DATA_FILE" ]]; then
        echo "Name: $user_name" > "$USER_DATA_FILE"
        echo "Attempts: $attempts" >> "$USER_DATA_FILE"
        echo "Score: $score" >> "$USER_DATA_FILE"
    else
        echo -e "Name: $user_name" >> "$USER_DATA_FILE"
        echo "Attempts: $attempts" >> "$USER_DATA_FILE"
        echo "Score: $score" >> "$USER_DATA_FILE"
    fi
}

# Function to display existing players
display_existing_players() {
    if [[ -f "$USER_DATA_FILE" ]]; then
        echo -e "${CYAN}Existing players:${RESET}"
        awk -F ": " '{print $2}' "$USER_DATA_FILE" | grep "Name" | nl
    else
        echo -e "${RED}No existing players found.${RESET}"
    fi
}

# Function to choose and scramble a word
get_scrambled_word() {
    local word=$1
    local scrambled_word=$(echo "$word" | fold -w1 | shuf | tr -d '\n')  # Scramble the word
    echo "$scrambled_word"
}

# Function to give a hint (reveal a letter)
give_hint() {
    local word=$1
    local hint_letter="${word:RANDOM%${#word}:1}"
    echo "Hint: One of the letters is $hint_letter"
}

# Function to get the user's choice for starting the game
start_game() {
    echo -n "Enter your name (or choose an existing player): "
    read USER_NAME

    # Check if the user wants to choose an existing player
    if [[ "$USER_NAME" == "existing" ]]; then
        display_existing_players
        echo -n "Enter the number of the player: "
        read PLAYER_NUMBER
        USER_NAME=$(awk -F ": " "NR==$PLAYER_NUMBER {print \$2}" "$USER_DATA_FILE" | sed 's/Name: //')
    fi

    # Difficulty levels
    echo -e "${YELLOW}Select difficulty:${RESET}"
    echo -e "1. Easy (3-5 letters)\n2. Medium (6-8 letters)\n3. Hard (9+ letters)"
    read -p "Choose difficulty level (1-3): " DIFFICULTY

    case $DIFFICULTY in
        1) WORD=$(grep -E '^.{3,5}$' "$WORDLIST" | shuf -n 1) ;;
        2) WORD=$(grep -E '^.{6,8}$' "$WORDLIST" | shuf -n 1) ;;
        3) WORD=$(grep -E '^.{9,}$' "$WORDLIST" | shuf -n 1) ;;
        *) echo -e "${RED}Invalid choice.${RESET} Defaulting to Medium."; WORD=$(grep -E '^.{6,8}$' "$WORDLIST" | shuf -n 1) ;;
    esac

    SCRAMBLED_WORD=$(get_scrambled_word "$WORD")  # Scramble the word for display
    ATTEMPTS=0
    SCORE=0
    MAX_ATTEMPTS=5  # Reduced to 5 guesses
}

# Start the game
start_game

# Game loop
while true; do
    echo -e "${CYAN}Scrambled Word: ${RESET}$SCRAMBLED_WORD"
    echo -n "Guess the word (or type 'hint' for a hint, 'exit' to quit): "
    read GUESS

    # Validate guess length to ensure it's not too short or long
    if [[ ${#GUESS} -lt 3 || ${#GUESS} -gt ${#WORD} ]]; then
        echo -e "${RED}Invalid guess length! Please try again.${RESET}"
        continue
    fi

    ATTEMPTS=$((ATTEMPTS + 1))

    # Check if the guess is correct
    if [[ "$GUESS" == "$WORD" ]]; then
        echo -e "${GREEN}Correct! The word was: $WORD${RESET}"
        SCORE=$((SCORE + 10))
        echo -e "${CYAN}Your Score: $SCORE${RESET}"
        break
    elif [[ "$GUESS" == "hint" ]]; then
        give_hint "$WORD"
    elif [[ "$GUESS" == "exit" ]]; then
        echo -e "${YELLOW}Game exited early.${RESET}"
        break
    else
        echo -e "${RED}Wrong guess! Try again.${RESET}"
    fi

    if [[ $ATTEMPTS -ge $MAX_ATTEMPTS ]]; then
        echo -e "${RED}You've reached the maximum number of attempts! The word was: $WORD${RESET}"
        break
    fi
done

# Save user data
save_user_data "$USER_NAME" "$ATTEMPTS" "$SCORE"

# Display all user scores
echo -e "\n${CYAN}Scores from all users:${RESET}"
awk -F ": " '{print $2}' "$USER_DATA_FILE" | grep "Score" | nl
