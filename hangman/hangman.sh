#!/bin/bash

# Wordlist path
WORDLIST="$HOME/games/data/wordlist.txt"
USER_DATA_FILE="$HOME/games/hangman/hangman_user_data.txt"
HIGH_SCORE_FILE="$HOME/games/hangman/high_score.txt"

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
BLUE='\033[0;34m'
RESET='\033[0m'

# Function to draw the hangman
draw_hangman() {
    clear
    echo "           _______"
    echo "          |       |"
    case $1 in
        0) echo "          |"; echo "          |"; echo "          |"; echo "          |"; echo "          |" ;;
        1) echo "          |       O"; echo "          |"; echo "          |"; echo "          |"; echo "          |" ;;
        2) echo "          |       O"; echo "          |       |"; echo "          |"; echo "          |"; echo "          |" ;;
        3) echo "          |       O"; echo "          |      /|"; echo "          |"; echo "          |"; echo "          |" ;;
        4) echo "          |       O"; echo "          |      /|\\"; echo "          |"; echo "          |"; echo "          |" ;;
        5) echo "          |       O"; echo "          |      /|\\"; echo "          |      /"; echo "          |"; echo "          |" ;;
        6) echo "          |       O"; echo "          |      /|\\"; echo "          |      / \\"; echo "          |"; echo "          |" ;;
    esac
    echo "         _|_"
    echo
}

# Function to provide a hint
generate_hint() {
    echo -e "${CYAN}Hint:${RESET} The word starts with '${WORD:0:1}' and ends with '${WORD: -1}'"
}

# Function to save user data
save_user_data() {
    local user_name=$1
    local time_taken=$2
    local correct_words=$3
    local wrong_words=$4
    local score=$5
    local guesses=$6

    # Create a temporary file
    temp_file=$(mktemp)

    # If user data file exists, copy non-matching lines to temp file
    if [[ -f "$USER_DATA_FILE" ]]; then
        grep -v "^Name: $user_name$" "$USER_DATA_FILE" > "$temp_file"
    fi

    # Append new data for the user
    {
        echo "Name: $user_name"
        echo "Time taken: $time_taken"
        echo "Correct words: $correct_words"
        echo "Wrong words: $wrong_words"
        echo "Score: $score"
        echo "Guesses: $guesses"
        echo "---" # Separator between user entries
    } >> "$temp_file"

    # Replace original file with updated data
    mv "$temp_file" "$USER_DATA_FILE"
}

# Function to get and display the high score
get_high_score() {
    if [[ -f "$HIGH_SCORE_FILE" ]]; then
        IFS='|' read -r high_score_name high_score_value < "$HIGH_SCORE_FILE"
    else
        high_score_name="None"
        high_score_value=0
    fi
}

# Function to update the high score if necessary
update_high_score() {
    local user_name=$1
    local score=$2
    if [[ "$score" -gt "$high_score_value" ]]; then
        echo "$user_name|$score" > "$HIGH_SCORE_FILE"
        echo -e "${CYAN}New High Score! $user_name with score $score${RESET}"
    fi
}

# Function to display existing players
display_existing_players() {
    if [[ -f "$USER_DATA_FILE" ]]; then
        echo "Existing players:"
        grep "Name:" "$USER_DATA_FILE" | cut -d ' ' -f 2- | sort -u | nl
    else
        echo "No existing players found."
    fi
}

# Function to display user data in a table
display_user_data() {
    local user_name=$1
    if [[ -f "$USER_DATA_FILE" ]]; then
        local user_data=$(sed -n "/^Name: $user_name$/,/^---$/p" "$USER_DATA_FILE")
        if [[ -n "$user_data" ]]; then
            echo -e "${BLUE}User Data for $user_name:${RESET}"
            echo -e "${YELLOW}+---------------+------------------+${RESET}"
            echo -e "${YELLOW}| ${CYAN}Statistic      ${YELLOW}| ${CYAN}Value            ${YELLOW}|${RESET}"
            echo -e "${YELLOW}+---------------+------------------+${RESET}"
            echo "$user_data" | while IFS=': ' read -r key value; do
                if [[ "$key" != "Name" && "$key" != "---" ]]; then
                    printf "${YELLOW}| ${CYAN}%-13s ${YELLOW}| ${GREEN}%-16s ${YELLOW}|${RESET}\n" "$key" "$value"
                fi
            done
            echo -e "${YELLOW}+---------------+------------------+${RESET}"
        else
            echo "No data found for $user_name"
        fi
    else
        echo "User data file not found."
    fi
}

# Function to select or create a new player
select_or_create_player() {
    echo "Do you want to continue with an existing player or create a new one?"
    echo "1. Continue with existing player"
    echo "2. Create a new player"
    read -n 1 -s choice

    case $choice in
        1)
            clear
            display_existing_players
            echo "Enter the number of the player you want to select:"
            read -n 1 -s player_number
            USER_NAME=$(grep "Name:" "$USER_DATA_FILE" | cut -d ' ' -f 2- | sort -u | sed -n "${player_number}p")
            if [[ -n "$USER_NAME" ]]; then
                echo "You have selected: $USER_NAME"
                display_user_data "$USER_NAME"
            else
                echo -e "${RED}Invalid selection. Please try again.${RESET}"
                select_or_create_player
            fi
            ;;
        2)
            echo "Enter a new player name:"
            read USER_NAME
            echo "Creating new player: $USER_NAME"
            ;;
        *)
            echo -e "${RED}Invalid option. Please choose 1 or 2.${RESET}"
            select_or_create_player
            ;;
    esac
}

# Function to play the game
play_game() {
    # Difficulty levels
    echo -e "${YELLOW}Select difficulty:${RESET}"
    echo -e "1. Easy (3-5 letters)\n2. Medium (6-8 letters)\n3. Hard (9+ letters)"
    read -n 1 -s DIFFICULTY

    case $DIFFICULTY in
        1) WORD=$(grep -E '^.{3,5}$' "$WORDLIST" | shuf -n 1); echo "You have selected: Easy" ;;
        2) WORD=$(grep -E '^.{6,8}$' "$WORDLIST" | shuf -n 1); echo "You have selected: Medium" ;;
        3) WORD=$(grep -E '^.{9,}$' "$WORDLIST" | shuf -n 1); echo "You have selected: Hard" ;;
        *) echo -e "${RED}Invalid choice.${RESET} Defaulting to Medium."; WORD=$(grep -E '^.{6,8}$' "$WORDLIST" | shuf -n 1) ;;
    esac

    WORD_LENGTH=${#WORD}
    GUESSED=""
    ATTEMPTS_LEFT=6
    WRONG_GUESSES=""
    SCORE=0
    CORRECT_GUESSES=0
    WRONG_GUESSES_COUNT=0
    NUMBER_OF_GUESSES=0

    # Timer setup
    echo -e "${YELLOW}Would you like to enable a timer?${RESET} (y/n)"
    read -n 1 -s TIMER_ENABLED

    if [[ "$TIMER_ENABLED" == "y" ]]; then
        START_TIME=$(date +%s) # Record the start time
        echo "Timer enabled."
    else
        echo "Timer disabled."
    fi

    # Initialize hidden word display
    HIDDEN_WORD=$(printf '_%.0s' $(seq 1 $WORD_LENGTH))

    # Get and display the high score
    get_high_score

    # Game loop
    while [[ $ATTEMPTS_LEFT -gt 0 ]]; do
        # Calculate elapsed time if the timer is enabled
        if [[ "$TIMER_ENABLED" == "y" ]]; then
            CURRENT_TIME=$(date +%s)
            TIMER=$((CURRENT_TIME - START_TIME))
        fi

        draw_hangman $((6 - ATTEMPTS_LEFT))
        echo -e "${GREEN}Word:${RESET} $HIDDEN_WORD"
        echo -e "${RED}Wrong guesses:${RESET} $WRONG_GUESSES"
        echo -e "${YELLOW}Attempts left:${RESET} $ATTEMPTS_LEFT"
        echo -e "${CYAN}Score:${RESET} $SCORE"
        [[ "$TIMER_ENABLED" == "y" ]] && echo -e "${CYAN}Time elapsed:${RESET} ${TIMER}s"
        echo -e "${CYAN}High Score:${RESET} $high_score_name with $high_score_value"
        generate_hint
        echo
        echo -n "Guess a letter: "
        read -n 1 GUESS
        echo

        # Ensure input is lowercase
        GUESS=$(echo "$GUESS" | tr '[:upper:]' '[:lower:]')

        # Check if input is valid
        if [[ ! "$GUESS" =~ [a-z] ]]; then
            echo -e "${RED}Invalid input. Please enter a letter.${RESET}"
            sleep 1
            continue
        fi

        # Check if already guessed
        if [[ "$GUESSED" == *"$GUESS"* ]]; then
            echo -e "${YELLOW}You already guessed '${GUESS}'. Try again.${RESET}"
            sleep 1
            continue
        fi

        # Add to guessed letters
        GUESSED+="$GUESS"
        NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

        # Check if the guess is correct
        if [[ "$WORD" == *"$GUESS"* ]]; then
            # Reveal the letter in the hidden word
            for i in $(seq 0 $((WORD_LENGTH - 1))); do
                if [[ "${WORD:$i:1}" == "$GUESS" ]]; then
                    HIDDEN_WORD="${HIDDEN_WORD:0:$i}$GUESS${HIDDEN_WORD:$((i + 1))}"
                fi
            done

            # Update score
            SCORE=$((SCORE + 10))
            CORRECT_GUESSES=$((CORRECT_GUESSES + 1))

            # Check if the word is fully guessed
            if [[ "$HIDDEN_WORD" == "$WORD" ]]; then
                draw_hangman $((6 - ATTEMPTS_LEFT))
                echo -e "${GREEN}Word:${RESET} $HIDDEN_WORD"
                echo -e "${CYAN}Congratulations! You guessed the word: ${GREEN}$WORD${RESET}"
                echo -e "${CYAN}Final Score:${RESET} $SCORE"
                [[ "$TIMER_ENABLED" == "y" ]] && echo -e "${CYAN}Time taken:${RESET} ${TIMER}s"
                save_user_data "$USER_NAME" "$TIMER" "$CORRECT_GUESSES" "$WRONG_GUESSES_COUNT" "$SCORE" "$NUMBER_OF_GUESSES"
                update_high_score "$USER_NAME" "$SCORE"
                display_user_data "$USER_NAME"
                return 0
            fi
        else
            # Incorrect guess
            WRONG_GUESSES+="$GUESS "
            WRONG_GUESSES_COUNT=$((WRONG_GUESSES_COUNT + 1))
            ATTEMPTS_LEFT=$((ATTEMPTS_LEFT - 1))
            SCORE=$((SCORE - 5))
        fi
    done

    # Game over
    draw_hangman 6
    echo -e "${RED}Game Over! You've been hanged💀! The word was: ${GREEN}$WORD${RESET}"
    echo -e "${CYAN}Final Score:${RESET} $SCORE"
    [[ "$TIMER_ENABLED" == "y" ]] && echo -e "${CYAN}Time taken:${RESET} ${TIMER}s"
    save_user_data "$USER_NAME" "$TIMER" "$CORRECT_GUESSES" "$WRONG_GUESSES_COUNT" "$SCORE" "$NUMBER_OF_GUESSES"
    update_high_score "$USER_NAME" "$SCORE"
    display_user_data "$USER_NAME"
    return 1
}

# Main game loop
while true; do
    # Prompt for player selection
    select_or_create_player

    # Play the game
    play_game
    game_result=$?

    if [ $game_result -eq 0 ]; then
        echo -e "${GREEN}You won! Would you like to play again?${RESET}"
    else
        echo -e "${RED}You lost. Would you like to try again?${RESET}"
    fi

    echo "1. Play again"
    echo "2. Exit"
    read -n 1 -s choice

    case $choice in
        1)
            echo "Starting a new game..."
            ;;
        2)
            echo -e "${CYAN}Thanks for playing! Goodbye, $USER_NAME.${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting the game.${RESET}"
            exit 1
            ;;
    esac
done
