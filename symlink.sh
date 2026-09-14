#!/usr/bin/env sh

# Directory this script lives in, regardless of where the repo is cloned.
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat <<EOF
Usage: symlink.sh --script=<type> [--target=<path>] [--mode=<mode>]

Links a script from this repo to a target location and makes it
executable, either as a symlink or as a wrapper file. A wrapper is a
plain file that execs the real script back in this repo; use it where
symlinks aren't accepted (e.g. Termux:Tasker).

Options:
  --script=<type>   Which script to link (required). Supported types:
                       termux-sync                termux-scripts/sync.sh
                       termux-power-connected      termux-scripts/power_connected.sh
                       termux-power-disconnected   termux-scripts/power_disconnected.sh
  --target=<path>   Destination path for the link. Defaults to the
                     type's standard location:
                       termux-sync                ~/.termux/tasker/sync.sh
                       termux-power-connected      ~/.termux/tasker/power_connected.sh
                       termux-power-disconnected   ~/.termux/tasker/power_disconnected.sh
  --mode=<mode>     How to link the script. One of:
                       symlink   create a symlink (default)
                       wrapper   write a plain file that execs the source script
  -h, --help        Show this help message and exit
EOF
}

SCRIPT_TYPE=""
TARGET=""
MODE=""

for arg in "$@"; do
    case "$arg" in
        --script=*)
            SCRIPT_TYPE="${arg#--script=}"
            ;;
        --target=*)
            TARGET="${arg#--target=}"
            ;;
        --mode=*)
            MODE="${arg#--mode=}"
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
MODE="${MODE:-symlink}"

mkdir -p "$(dirname "$TARGET")"
chmod +x "$SOURCE"

case "$MODE" in
    symlink)
        ln -sf "$SOURCE" "$TARGET"
        echo "Symlink created: $TARGET -> $SOURCE"
        ;;
    wrapper)
        # Write a plain wrapper file instead of a symlink, since some
        # consumers (e.g. Termux:Tasker) refuse to run symlinked scripts.
        # The wrapper just execs the real script back in this repo,
        # forwarding any arguments.
        cat > "$TARGET" <<WRAPPER_EOF
#!/usr/bin/env sh
exec "$SOURCE" "\$@"
WRAPPER_EOF
        chmod +x "$TARGET"
        echo "Wrapper installed: $TARGET -> $SOURCE"
        ;;
    *)
        echo "Error: unknown mode '$MODE'" >&2
        usage
        exit 1
        ;;
esac
