#!/usr/bin/env sh

# Directory this script lives in, regardless of where the repo is cloned.
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat <<EOF
Usage: symlink.sh --script=<type> [--target=<path>]

Symlinks a script from this repo to a target location and makes it
executable.

Options:
  --script=<type>   Which script to link (required). Supported types:
                       termux-sync                termux-scripts/sync.sh
                       termux-power-connected      termux-scripts/power_connected.sh
                       termux-power-disconnected   termux-scripts/power_disconnected.sh
  --target=<path>   Destination path for the symlink. Defaults to the
                     type's standard location:
                       termux-sync                ~/.termux/tasker/sync.sh
                       termux-power-connected      ~/.termux/tasker/power_connected.sh
                       termux-power-disconnected   ~/.termux/tasker/power_disconnected.sh
  -h, --help        Show this help message and exit
EOF
}

SCRIPT_TYPE=""
TARGET=""

for arg in "$@"; do
    case "$arg" in
        --script=*)
            SCRIPT_TYPE="${arg#--script=}"
            ;;
        --target=*)
            TARGET="${arg#--target=}"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown argument '$arg'" >&2
            usage
            exit 1
            ;;
    esac
done

case "$SCRIPT_TYPE" in
    termux-sync)
        SOURCE="$DOTFILES_DIR/termux-scripts/sync.sh"
        DEFAULT_TARGET="$HOME/.termux/tasker/sync.sh"
        ;;
    termux-power-connected)
        SOURCE="$DOTFILES_DIR/termux-scripts/power_connected.sh"
        DEFAULT_TARGET="$HOME/.termux/tasker/power_connected.sh"
        ;;
    termux-power-disconnected)
        SOURCE="$DOTFILES_DIR/termux-scripts/power_disconnected.sh"
        DEFAULT_TARGET="$HOME/.termux/tasker/power_disconnected.sh"
        ;;
    "")
        echo "Error: --script is required" >&2
        usage
        exit 1
        ;;
    *)
        echo "Error: unknown script type '$SCRIPT_TYPE'" >&2
        usage
        exit 1
        ;;
esac

TARGET="${TARGET:-$DEFAULT_TARGET}"

mkdir -p "$(dirname "$TARGET")"
ln -sf "$SOURCE" "$TARGET"
chmod +x "$SOURCE"

echo "Symlink created: $TARGET -> $SOURCE"
