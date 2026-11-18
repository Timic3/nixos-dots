# Run a Windows game with Proton (via umu) inside a bubblewrap sandbox.
#
# Usage: sandbox-game --setup <game-dir>                       one time: download the Steam runtime + create the prefix
#                                                              (network on, the game is NOT run)
#        sandbox-game [--net] [--x11] <game-dir> <exe> [args]  run the game
#
#   --net  share the network (off by default)
#   --x11  use Xwayland instead of Wine's Wayland driver, for games that break on Wayland.
#          X11 clients can read other X11 windows and the keystrokes sent to them.
#
# The game sees: its own directory (rw), a fake $HOME holding its Wine prefix (rw),
# /nix/store and /etc (ro), the GPU, the Wayland socket (or X11 with --x11) and the audio
# socket. Nothing else from your real home, no D-Bus. Per-game state lives in
# ~/games/sandbox/<game-dir-name>/, the Steam runtime (~700 MB) is shared in
# ~/games/sandbox/.umu-runtime/.
#
# Keep game dirs out of /tmp: umu's Steam FHS wrapper uses a private /tmp and won't see them.
#
# PROTONPATH and UMU_RUN come from modules/apps/gaming.nix.
# Built with writeShellApplication, which adds the shebang and `set -euo pipefail`.

: "${UMU_RUN:=umu-run}"
: "${PROTONPATH:?set PROTONPATH to a Proton dir, e.g. pkgs.proton-ge-bin.steamcompattool}"

usage() { echo "usage: sandbox-game --setup <game-dir> | sandbox-game [--net] [--x11] <game-dir> <exe> [args...]" >&2; exit 1; }

mode=run net=0 x11=0
while [[ ${1:-} == --* ]]; do
  case $1 in
    --setup) mode=setup net=1 ;;
    --net)   net=1 ;;
    --x11)   x11=1 ;;
    *)       usage ;;
  esac
  shift
done
[[ $# -ge 1 ]] || usage

game_dir=$(realpath "$1"); shift
state="$HOME/games/sandbox/$(basename "$game_dir")"
runtime="$HOME/games/sandbox/.umu-runtime"   # Shared by all games, only ever touched from inside sandboxes
mkdir -p "$state/home" "$runtime"

if [[ $mode == setup ]]; then
  cmd=("$UMU_RUN" wineboot -u)
else
  [[ $# -ge 1 ]] || usage
  exe=$1; shift
  [[ $exe = /* ]] || exe="$game_dir/$exe"
  cmd=("$UMU_RUN" "$exe" "$@")
fi

args=(
  --unshare-all --die-with-parent --new-session --clearenv
  --ro-bind /nix/store /nix/store
  --ro-bind /etc /etc
  --ro-bind /bin /bin
  --ro-bind /usr /usr
  --ro-bind /run/current-system /run/current-system
  --ro-bind-try /run/opengl-driver /run/opengl-driver
  --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
  --ro-bind /sys /sys
  --proc /proc
  --dev /dev
  --tmpfs /tmp
  --bind "$state/home" "$HOME"
  --bind "$runtime" "$HOME/.local/share/umu"
  --bind "$game_dir" "$game_dir"
  --chdir "$game_dir"
  --setenv HOME "$HOME"
  --setenv USER "$USER"
  --setenv PATH /run/current-system/sw/bin
  --setenv LANG "${LANG:-C.UTF-8}"
  --setenv WINEPREFIX "$HOME/prefix"
  --setenv GAMEID "umu-$(basename "$game_dir")"
  --setenv PROTONPATH "$PROTONPATH"
)
[[ -n ${LOCALE_ARCHIVE:-} ]] && args+=(--setenv LOCALE_ARCHIVE "$LOCALE_ARCHIVE")

# GPU (NVIDIA + DRM render nodes)
for d in /dev/dri /dev/nvidia*; do [[ -e $d ]] && args+=(--dev-bind "$d" "$d"); done

# Runtime dir with only the audio socket (no Wayland, D-Bus, ssh/gpg agents, podman, ...)
if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
  args+=(--perms 0700 --dir "$XDG_RUNTIME_DIR" --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR")
  if [[ -S $XDG_RUNTIME_DIR/pulse/native ]]; then
    args+=(--ro-bind "$XDG_RUNTIME_DIR/pulse/native" "$XDG_RUNTIME_DIR/pulse/native"
           --setenv PULSE_SERVER "unix:$XDG_RUNTIME_DIR/pulse/native")
  fi
fi

# Display: only the Wayland socket by default. With --x11, only the current X11 display's
# socket; without --net the abstract X11 sockets are unreachable too, so under gamescope
# the game can't reach the main Xwayland.
if [[ $x11 == 1 ]]; then
  [[ -n ${DISPLAY:-} ]] || { echo "sandbox-game: --x11 needs DISPLAY" >&2; exit 1; }
  n=${DISPLAY#*:}; n=${n%%.*}
  args+=(--ro-bind "/tmp/.X11-unix/X$n" "/tmp/.X11-unix/X$n" --setenv DISPLAY "$DISPLAY")
  [[ -n ${XAUTHORITY:-} && -e $XAUTHORITY ]] && args+=(--ro-bind "$XAUTHORITY" "$XAUTHORITY" --setenv XAUTHORITY "$XAUTHORITY")
else
  [[ -n ${WAYLAND_DISPLAY:-} && -n ${XDG_RUNTIME_DIR:-} ]] || { echo "sandbox-game: no Wayland session, try --x11" >&2; exit 1; }
  sock="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
  args+=(--ro-bind "$sock" "$sock" --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY"
         --setenv PROTON_ENABLE_WAYLAND 1)   # Proton-GE: Wine's Wayland driver instead of Xwayland
fi

if [[ $net == 1 ]]; then
  args+=(--share-net)
else
  args+=(--setenv UMU_RUNTIME_UPDATE 0)   # Don't try to update the runtime offline
fi

exec bwrap "${args[@]}" -- "${cmd[@]}"
