#!/bin/bash

# Define the wordlist file
WORDLIST="$HOME/games/wordlist.txt"

# Create the file if it doesn't exist
touch "$WORDLIST"

# Total number of words to generate
TOTAL_WORDS=1000
BATCH_SIZE=50
TOTAL_BATCHES=$((TOTAL_WORDS / BATCH_SIZE))

# Initialize progress
CURRENT_WORDS=0

# Function to display progress
show_progress() {
    local PROGRESS=$((CURRENT_WORDS * 100 / TOTAL_WORDS))
    local BAR_LENGTH=$((PROGRESS / 2))
    local BAR=$(printf "%-${BAR_LENGTH}s" "#" | tr ' ' '#')
    local EMPTY=$((50 - BAR_LENGTH))
    local SPACES=$(printf "%-${EMPTY}s" " ")
    echo -ne "\rProgress: [${BAR}${SPACES}] ${PROGRESS}% (${CURRENT_WORDS}/${TOTAL_WORDS} words)"
}

# Fetch random words and update progress
for i in $(seq 1 "$TOTAL_BATCHES"); do
    WORDS=$(curl -s "https://random-word-api.herokuapp.com/word?number=$BATCH_SIZE" | jq -r '.[]')
    for WORD in $WORDS; do
        # Only add unique words
        if ! grep -qx "$WORD" "$WORDLIST"; then
            echo "$WORD" >> "$WORDLIST"
            CURRENT_WORDS=$((CURRENT_WORDS + 1))
        fi
    done
    show_progress
done

# Final message
echo -e "\n1000 random and unique words have been saved to $WORDLIST."
