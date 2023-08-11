#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202304292253-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  LICENSE.md
# @@ReadME           :  build.sh --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Monday, May 01, 2023 17:47 EDT
# @@File             :  build.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/build
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2317
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="termite"                    # Set build name
BUILD_NAME="${BUILD_NAME:-$APPNAME}" # Set build name
VERSION="202304292253-git"           # Set version
USER="${SUDO_USER:-${USER}}"         # Set username
HOME="${USER_HOME:-${HOME}}"         # Set home Directory
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"   # Set the dir to script
PATH="${PATH//:./}"                  # Remove . from path
SET_BUILD_SRC_URL="$BUILD_SRC_URL"   # Set url to git repo
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set variables
exitCode=10
NC="$(tput sgr0 2>/dev/null)"
RESET="$(tput sgr0 2>/dev/null)"
BLACK="\033[0;30m"
RED="\033[1;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
ORANGE="\033[0;33m"
LIGHTRED='\033[1;31m'
BG_GREEN="\[$(tput setab 2 2>/dev/null)\]"
BG_RED="\[$(tput setab 9 2>/dev/null)\]"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TERMITE_LOG_DIR="${TERMITE_LOG_DIR:-$HOME/.local/log/builds}"                           #
BUILD_SCRIPT_SRC_DIR="${BUILD_SCRIPT_SRC_DIR:-$HOME/.local/share/${BUILD_NAME}/source}" # set the source dir
BUILD_LOG_FILE="${BUILD_LOG_FILE:-$TERMITE_LOG_DIR/${BUILD_NAME}_build.log}"            # set log files
BUILD_LOG_DIR="$(dirname "$BUILD_LOG_FILE")"                                            # get the log directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
trap 'exitCode=${exitCode:-0};[ -n "$TERMITE_TEMP_FILE" ] && [ -f "$TERMITE_TEMP_FILE" ] && rm -Rf "$TERMITE_TEMP_FILE" |&__devnull;exit ${exitCode:-0}' EXIT
[ "$1" == "--debug" ] && set -xo pipefail && export SCRIPT_OPTS="--debug" && export _DEBUG="on"
[ "$1" == "--raw" ] && export SHOW_RAW="true"
set -Eo pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__logr() {
  eval "$*" 2>"$TERMITE_LOG_DIR/$APPNAME.log.err" >"$TERMITE_LOG_DIR/$APPNAME.log"
  return $?
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Send all output to /dev/null
__devnull() {
  tee &>/dev/null && exitCode=0 || exitCode=1
  return ${exitCode:-0}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# Send errors to /dev/null
__devnull2() {
  [ -n "$1" ] && local cmd="$1" && shift 1 || return 1
  eval $cmd "$*" 2>/dev/null && exitCode=0 || exitCode=1
  return ${exitCode:-0}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# See if the executable exists
__cmd_exists() {
  [ -n "$1" ] && local exitCode="" || return 0
  for cmd in "$@"; do
    builtin type -P "$cmd" &>/dev/null && exitCode+=0 || exitCode+=1
  done
  [ $exitCode -eq 0 ] || exitCode=3
  return ${exitCode:-0}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check for a valid internet connection
__am_i_online() {
  local exitCode=0
  curl -q -LSsfI --max-time 2 --retry 1 "${1:-http://1.1.1.1}" 2>&1 | grep -qi 'server:.*cloudflare' || exitCode=4
  return ${exitCode:-0}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# colorization
if [ "$SHOW_RAW" = "true" ]; then
  printf_color() { printf '%b\n' "$1" | tr -d '\t' | sed '/^%b$/d;s,\x1B\[ 0-9;]*[a-zA-Z],,g'; }
else
  printf_color() { printf "%b\n" "$(tput setaf "${2:-7}" 2>/dev/null)" "$1" "$(tput sgr0 2>/dev/null)"; }
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# output version
__version() { printf '%b\n' "${GREEN:-}$VERSION${NC:-}"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# send notifications
__notifications() {
  __cmd_exists notifications || return
  [ "$TERMITE_NOTIFY_ENABLED" = "yes" ] || return
  [ "$SEND_NOTIFICATION" = "no" ] && return
  (
    set +x
    export SCRIPT_OPTS="" _DEBUG=""
    export NOTIFY_GOOD_MESSAGE="${NOTIFY_GOOD_MESSAGE:-$TERMITE_GOOD_MESSAGE}"
    export NOTIFY_ERROR_MESSAGE="${NOTIFY_ERROR_MESSAGE:-$TERMITE_ERROR_MESSAGE}"
    export NOTIFY_CLIENT_ICON="${NOTIFY_CLIENT_ICON:-$TERMITE_NOTIFY_CLIENT_ICON}"
    export NOTIFY_CLIENT_NAME="${NOTIFY_CLIENT_NAME:-$TERMITE_NOTIFY_CLIENT_NAME}"
    export NOTIFY_CLIENT_URGENCY="${NOTIFY_CLIENT_URGENCY:-$TERMITE_NOTIFY_CLIENT_URGENCY}"
    notifications "$@"
    retval=$?
    return $retval
  ) |& __devnull &
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf_readline() {
  local color="$1"
  set -o pipefail
  while read line; do
    printf_color "$line" "${color:-$WHITE}"
  done |& tee
  set +o pipefail
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__help() {
  [ -z "$ARRAY" ] || local array="[${ARRAY//,/ }]"
  [ -z "$LONGOPTS" ] || local opts="[--${LONGOPTS//,/ --}]"
  printf_color "Usage: $APPNAME $opts $array" "$BLUE"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup build function
__make_build() {
  local exitCode=1
  local exitCode_make="0"
  local exitCode_cmake="0"
  local exitCode_configure="0"
  __execute_pre_build
  if [ -f "$BUILD_SCRIPT_SRC_DIR/CMakeLists.txt" ]; then
    mkdir -p "$BUILD_SCRIPT_SRC_DIR/build" && cd "$BUILD_SCRIPT_SRC_DIR/build" || exit 10
    cmake $CMAKE_ARGS 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull || exitCode+=1
    make $MAKE_ARGS 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull || exitCode+=1
    sudo make install DESTDIR="$BUILD_DESTDIR" 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull || exitCode+=1
    exitCode_cmake="$?"
  elif [ -f "$BUILD_SCRIPT_SRC_DIR/configure" ]; then
    printf_color "Running configure" "$GREEN"
    make clean 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull
    ./configure --prefix="$BUILD_DESTDIR" $CONFIGURE_ARGS 2>&1 |
      tee -a "$BUILD_LOG_FILE" |& __devnull
    exitCode_configure="$?"
    if [ -f "$BUILD_SCRIPT_SRC_DIR/Makefile" ]; then
      printf_color "Running make" "$GREEN"
      make $MAKE_ARGS 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull || exitCode+=1
      sudo make 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull &&
        sudo make install
      exitCode_make="$?"
    fi
  elif [ -f "$BUILD_SCRIPT_SRC_DIR/Makefile" ]; then
    printf_color "Running make" "$GREEN"
    make clean 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull
    make $MAKE_ARGS 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull || exitCode+=1
    sudo make install DESTDIR="$BUILD_DESTDIR" 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull
    exitCode_make="$?"
  fi
  if [ "$exitCode_configure" = 0 ] && [ "$exitCode_make" = 0 ] && [ "$exitCode_cmake" = 0 ]; then
    exitCode=0
  else
    printf_color "Building $BUILD_NAME has failed" "$RED"
    exit 9
  fi
  return "${exitCode:-0}"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'
# Set main functions
__run_git() {
  if [ -d "$BUILD_SCRIPT_SRC_DIR/.git" ]; then
    printf_color "Updating the git repo" "$CYAN"
    git -C "$BUILD_SCRIPT_SRC_DIR" reset --hard 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull && git -C "$BUILD_SCRIPT_SRC_DIR" pull 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull
    if [ $? = 0 ]; then
      return 0
    else
      printf_color "Failed to update: $BUILD_SCRIPT_SRC_DIR" "$RED"
      exit 1
    fi
  elif [ -n "$BUILD_SRC_URL" ]; then
    printf_color "Cloning the git repo to: $BUILD_SCRIPT_SRC_DIR" "$CYAN"
    git clone "$BUILD_SRC_URL" "$BUILD_SCRIPT_SRC_DIR" 2>&1 | tee -a "$BUILD_LOG_FILE" |& __devnull
    if [ $? = 0 ]; then
      return 0
    else
      printf_color "Failed to clone: $BUILD_SRC_URL" "$RED"
      exit 1
    fi
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__check_log() {
  local exitCode="$?"
  if [ -f "$BUILD_LOG_FILE" ]; then
    errors="$(grep -i 'fatal error' "$BUILD_LOG_FILE" || echo '')"
    warnings="$(grep -i 'warning: ' "$BUILD_LOG_FILE" || echo '')"
    if [ -n "$warnings" ]; then
      printf_color "The following warnings have occurred:" "$RED"
      echo -e "$warnings" |& printf_readline
      printf_color "Log file saved to $BUILD_LOG_FILE" "$YELLOW"
      exitCode=0
    fi
    if [ -n "$errors" ] || [ "$exitCode" -ne 0 ]; then
      printf_color "The following errors have occurred:" "$RED"
      echo -e "$errors" |& printf_readline
      printf_color "Log file saved to $BUILD_LOG_FILE" "$YELLOW"
      exitCode=1
    else
      rm -Rf "$BUILD_LOG_FILE" |& __devnull
      printf_color "Build of $BUILD_NAME has completed without error" "$GREEN"
      exitCode=0
    fi
  fi
  return "${exitCode:-0}"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__packages() {
  local exitCode=0
  [ "$PACKAGE_LIST" = " " ] && return
  # Install required packages
  if [ -n "$PACKAGE_LIST" ]; then
    printf_color "Installing required packages" "$BLUE"
    if __cmd_exists pkmgr; then
      for pkg in $PACKAGE_LIST; do
        pkmgr silent install "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    elif __cmd_exists apt; then
      for pkg in $PACKAGE_LIST; do
        apt install -yy "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    elif __cmd_exists pacman; then
      for pkg in $PACKAGE_LIST $PACMAN; do
        pacman -S --noconfirm "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    elif __cmd_exists apt-get; then
      for pkg in $PACKAGE_LIST $APT; do
        apt-get install -yy "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    elif __cmd_exists apt-get; then
      for pkg in $PACKAGE_LIST $APT; do
        apt-get install -yy "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    elif __cmd_exists dnf; then
      for pkg in $PACKAGE_LIST $YUM; do
        dnf install -yy "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    elif __cmd_exists yum; then
      for pkg in $PACKAGE_LIST $YUM; do
        yum install -yy "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    elif __cmd_exists apk; then
      for pkg in $PACKAGE_LIST $APK; do
        apk add "$pkg" |& __devnull && true || false
        [ $? = 0 ] && __logr "Installed $pkg" || { exitCode=$((exitCode + 1)) && __logr "Warning: Failed to installed $pkg"; }
      done
    fi
    [ $exitCode -eq 0 ] && printf_color "Done trying to install packages" "$YELLOW" || printf_color "Installing packages finished with errors" "$YELLOW"
    return $exitCode
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__init() {
  BUILD_SRC_URL="${BUILD_SRC_URL:-$SET_BUILD_SRC_URL}"
  BUILD_BIN="$(builtin type -P "$BUILD_NAME" || echo "$BUILD_NAME")"
  [ -d "$BUILD_LOG_DIR" ] || mkdir -p "$BUILD_LOG_DIR"
  if [ -z "$BUILD_FORCE" ] && __cmd_exists "$BUILD_NAME"; then
    printf_color "$BUILD_NAME is already installed at: ${GREEN}$BUILD_BIN${NC}" "$RED" 1>&2
    printf_color "run with --force to rebuild" "$YELLOW" 1>&2
    exit 0
  fi
  printf_color "Initializing build script for $BUILD_NAME" "$PURPLE"
  printf_color "Saving all output to $BUILD_LOG_FILE" "$CYAN"
  sleep 3
  if command -v "$BUILD_NAME" | grep -q '^/bin' || command -v "$BUILD_NAME" | grep -q '^/usr/bin'; then
    BUILD_DESTDIR="/usr"
  else
    BUILD_DESTDIR="${BUILD_DESTDIR:-/usr/local}"
  fi
  if ! builtin cd "$BUILD_SCRIPT_SRC_DIR"; then
    printf_color "Failed to cd into $BUILD_SCRIPT_SRC_DIR" "$RED"
    exit 1
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__execute_pre_build() {
  local statusCode=0
  printf_green "building vte-ng"
  devnull cd "$(dirname "${BASH_SOURCE[0]}")"
  git_clone https://github.com/thestinger/vte-ng
  getexitcode "submodule init complete" || exit 1
  export LIBRARY_PATH="/usr/include/gtk-3.0:$LIBRARY_PATH"
  devnull cd "$(dirname "${BASH_SOURCE[0]}")/vte-ng"
  devnull ./autogen.sh
  getexitcode "autogen.sh finished" || exit 1
  devnull make
  getexitcode "make tfinished" || exit 1
  devnull requiresudo make install
  getexitcode "vte-ng has been installed" || exit 1
  return $statusCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check for needed applications
__cmd_exists bash || { printf_color "Missing: bash" "$RED" && exit 1; }
__cmd_exists make || { printf_color "Missing: make" "$RED" && exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
MAKE_ARGS="-j$(nproc) "
CMAKE_ARGS=".. "
CONFIGURE_ARGS=" "
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
PACKAGE_LIST=""
PACMAN=""
YUM=""
APT=""
APK=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
BUILD_SRC_URL="https://github.com/thestinger/termite"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Application Folders

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show warning message if variables are missing

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set options
SETARGS="$*"
SHORTOPTS=""
LONGOPTS="debug,force,help,options,raw,version"
ARRAY=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup application options
setopts=$(getopt -o "$SHORTOPTS" --long "$LONGOPTS" -n "$APPNAME" -- "$@" 2>/dev/null)
eval set -- "${setopts[@]}" 2>/dev/null
while :; do
  case "$1" in
  --debug)
    shift 1
    set -xo pipefail
    export SCRIPT_OPTS="--debug"
    export _DEBUG="on"
    __devnull() { tee || return 1; }
    __devnull2() { eval "$@" |& tee || return 1; }
    ;;
  --help)
    shift 1
    __help
    exit
    ;;
  --version)
    shift 1
    printf_color "$APPNAME Version: $VERSION" "$YELLOW"
    exit
    ;;
  --options)
    echo "--$LONGOPTS" | sed 's|,| --|g'
    exit
    ;;
  --force)
    shift 1
    BUILD_FORCE=true
    ;;
  --)
    shift 1
    break
    ;;
  esac
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Redefine functions based on options

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main application
__init
__run_git
__packages
__make_build
__check_log
exitCode=$?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check
if { [ "$exitCode" -eq 10 ] || [ "$exitCode" -eq 0 ]; } && [ -n "$(builtin type -P "$BUILD_NAME")" ]; then
  printf_color "Successfully installed $BUILD_NAME" "$GREEN"
  exitCode=0
else
  printf_color "Failed to install $BUILD_NAME" "$RED"
  exitCode=1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${exitCode:-0}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
