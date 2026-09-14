#!/data/data/com.termux/files/usr/bin/sh

: "${TARGET:?TARGET is required}"
: "${LOCAL_PATH:?LOCAL_PATH is required}"

# Derive a short hash from the required args so each distinct
# target/path combination gets its own state file.
ARGS_HASH=$(printf '%s|%s' "$TARGET" "$LOCAL_PATH" | sha256sum | cut -c1-6)

LOCAL_STATE_FILE="${LOCAL_STATE_FILE:-$HOME/.last_sync_time_${ARGS_HASH}}"
COOLDOWN_MINUTES="${COOLDOWN_MINUTES:-60}"

# Convert minutes to seconds
COOLDOWN_SECS=$((COOLDOWN_MINUTES * 60))
CURRENT_TIME=$(date +%s)

# Read local timestamp cache (default to 0 if file doesn't exist)
if [ -f "$LOCAL_STATE_FILE" ]; then
    LAST_TIME=$(cat "$LOCAL_STATE_FILE")
else
    LAST_TIME=0
fi

# Validate integer format
if ! [ "$LAST_TIME" -eq "$LAST_TIME" ] 2>/dev/null; then
    LAST_TIME=0
fi

TIME_DIFF=$((CURRENT_TIME - LAST_TIME))

# Step 1: Check time threshold locally BEFORE making network requests
if [ "$TIME_DIFF" -lt "$COOLDOWN_SECS" ]; then
    ELAPSED_MINUTES=$((TIME_DIFF / 60))
    echo "Skipping sync: Last sync was only ${ELAPSED_MINUTES} minute(s) ago."
    exit 0
fi

echo "Last sync was more than ${COOLDOWN_MINUTES} minutes ago (or never). Starting rsync..."

# Step 2: Only pass -e ssh when TARGET is a user@host:path SSH spec.
# Exclude rsync daemon syntax (host::module or user@host::module).
# Built with `set --` (not a plain string) so the whole ssh command
# stays one argument to -e instead of being word-split.
case "$TARGET" in
    *::*) set -- ;;
    *@*:*) set -- -e "ssh -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=2" ;;
    *) set -- ;;
esac

# Step 3: Run rsync with timeouts and socket keepalives
rsync -avz --timeout=30 "$@" "$LOCAL_PATH" "$TARGET"

# Step 4: Update timestamps only if rsync succeeds
if [ $? -eq 0 ]; then
    HUMAN_DATE=$(date "+%Y-%m-%d %H:%M:%S")

    # Save local timestamp
    echo "$CURRENT_TIME" > "$LOCAL_STATE_FILE"

    echo "Sync completed successfully."
else
    echo "Error: rsync failed or timed out. Timestamp not updated."
    exit 1
fi
