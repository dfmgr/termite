#!/usr/bin/env bash

SCRIPTNAME="$(basename $0)"
SCRIPTDIR="$(dirname "${BASH_SOURCE[0]}")"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# @Author      : Jason
# @Contact     : casjaysdev@casjay.net
# @File        : build
# @Created     : Mon, Dec 31, 2019, 00:00 EST
# @License     : WTFPL
# @Copyright   : Copyright (c) CasjaysDev
# @Description : termite build script
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set functions

if [ -f /usr/local/share/CasjaysDev/scripts/functions/app-installer.bash ]; then
  . /usr/local/share/CasjaysDev/scripts/functions/app-installer.bash
else
  curl -LSs https://github.com/dfmgr/installer/raw/main/functions/app-installer.bash -o /tmp/app-installer.bash || exit 1
  . /tmp/app-installer.bash
  rm_rf /tmp/app-installer.bash
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# get root privileges

printf_red "\t\tRequesting root privileges\n"
sudoask

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# clone

if ! cmd_exists termite; then
  printf_green "\n\t\tSetting up git\n"
  cd "$(dirname "${BASH_SOURCE[0]}")"
  git_clone https://github.com/thestinger/vte-ng
  getexitcode "submodule init complete" || exit 1
  git_clone https://github.com/thestinger/termite
  getexitcode "repos have been updated" || exit 1

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # build vte

  printf_green "\n\t\tbuilding vte-ng\n"
  export LIBRARY_PATH="/usr/include/gtk-3.0:$LIBRARY_PATH"
  devnull cd "$(dirname "${BASH_SOURCE[0]}")/vte-ng"
  devnull ./autogen.sh
  getexitcode "\t\tautogen.sh finished\n" || exit 1
  devnull make
  getexitcode "\t\tmake tfinished\n" || exit 1
  devnull requiresudo make install
  getexitcode "\t\tvte-ng has been installed\n" || exit 1

  #build termite

  printf_green "\n\t\tbuilding vte-ng\n"
  devnull cd "$(dirname "${BASH_SOURCE[0]}")/termite"
  devnull make
  getexitcode "\t\tmake tfinished\n" || exit 1
  devnull requiresudo make install &&
    devnull requiresudo ldconfig &&
    devnull requiresudo mkdir -p /lib/terminfo/x &&
    devnull requiresudo ln -s /usr/local/share/terminfo/x/xterm-termite /lib/terminfo/x/xterm-termite &&
    devnull requiresudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/termite 60
  getexitcode "\t\ttermite has been installed\n" || exit 1
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# exit
if [ ! -z "$EXIT" ]; then exit "$EXIT"; fi

# end
#/* vim set expandtab ts=2 noai
