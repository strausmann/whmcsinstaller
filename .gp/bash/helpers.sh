#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright © 2021 Apolo Pena
#
# helpers.sh
# Description:
# A variety of useful functions that depend on Gitpod and other
# binaries, aliases and functions such as code in .bashrc
#
# Notes:
# Do not execute this script without calling a function from it
# Additional Note: some functions use functions from .bashrc so the -i flag
# is the safest way to invoke functions from this script.
# Do not execute this script without calling a function from it.
#
# Usage: bash -i <function name> arg1 arg2 arg3 ...

# gls_version
# Description:
# Parses The gitpod-laravel-starter version from it's CHANGELOG.
# If the CHANGELOG.md cannot be found then a hardcoded string is used.
#
gls_version() {
  local hard version title file
  hard="1.5.0"
  title="Gitpod Laravel Starter Framework"
  file="$GITPOD_REPO_ROOT"/.gp/CHANGELOG.md
  if [[ -f $file ]]; then
    version=$(grep -oE "([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)?" "$file" | head -n 1)
  fi
  if [[ -n  $version ]];then echo "$title $version"; else echo "$title $hard"; fi
}
# start_server
# Description:
# Starts up the default server or a specific server ($1)
#
# Notes:
# It is assumed that starter.ini is in the project root.
# Valid servers are: apache, php
#
# Usage:
# Example: start the default server
# start_server
start_server() {
  local usage='Usage: start_server [server-type]'
  local err_prefix='Error: start_server():'
  local server s err_msg
  s=$(bash .gp/bash/utils.sh parse_ini_value starter.ini development default_server)
  if [[ -z "$1" ]]; then
    server=$(echo "$s" | tr '[:upper:]' '[:lower:]')
    err_msg="$err_prefix invalid default server: $server. Check the file $GITPOD_REPO_ROOT/starter.ini"
  else
    server=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    err_msg="$err_prefix invalid server type: $1"
  fi 
  case $server in
    'php')
    start_php_dev
    ;;
    'apache')
    start_apache
    ;;
    'nginx')
    start_nginx
    ;;
    *)
    echo "$err_msg"
    ;;
  esac
}

# show_first_run_summary
# Description:
# Outputs a summarized and colorized dump of /var/log/workspace-image.log
# and /var/log/workspace-init.log
#
# Usage:
# show_first_run_summary
show_first_run_summary() {
  local ui
  workspace_log='/var/log/workspace-image.log'
  init_log='/var/log/workspace-init.log'
  echo -e "\n\e[38;5;171mSUMMARY 👀\e[0m\n"
  echo -e "\e[38;5;194mResults of building the workspace image\e[0m \e[38;5;34m$workspace_log\e[0m ➥\e[38;5;183m"
  cat $workspace_log
  echo -en "\e[0m"
  echo -e "\e[38;5;194mResults of the gitpod initialization\e[0m \e[38;5;34m$init_log\e[0m ➥"
  grc -c .gp/conf/grc/init-log.conf cat $init_log
  [ -d 'public/phpmyadmin' ] &&
  echo -en "\e[38;5;208m" &&
  echo -e "$(cat .gp/snippets/messages/phpmyadmin-security.txt)" &&
  echo -e "\e[0m"
  show_powered_by
  echo -e "\e\n[38;5;171mALL DONE 🚀\e[0m"
  echo -e "\n\e[38;5;194mIf everything looks good in the summary above then push any new\nproject files to your git repository. Happy coding 👩‍💻👨‍💻\e[0m"
}

# show_powered_by
# Description:
# Outputs a summary showing what is installed: Laravel, laravel/ui, react, react-dom and vue
#
# Usage:
# show_powered_by
show_powered_by() {
  local ver file ver_pattern="([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)"
  echo "This project is powered by:"
  echo -en "\e[38;5;34m"
  gls_version
  echo "PHP $(bash .gp/bash/utils.sh php_version)"
  echo -e "$(php artisan --version)"
  composer show | grep laravel/ui >/dev/null && ui=1 || ui=0
  if [[ $ui -eq 1 ]]; then
    [[ $(grep laravel/ui/tree/ composer.lock) =~ $ver_pattern ]] && echo "laravel/ui ${BASH_REMATCH[1]}"
  fi
  file=node_modules/react/cjs/react.development.js
  if [[ -e $file ]]; then
    [[ $(head -n 1 "$file") =~ $ver_pattern ]] && echo "react ${BASH_REMATCH[1]}"
  fi
  file=node_modules/react-dom/cjs/react-dom.development.js
  if [[ -e $file ]]; then
    [[ $(head -n 1 "$file") =~ $ver_pattern ]] && echo "react-dom ${BASH_REMATCH[1]}"
  fi
  file=node_modules/vue/dist/vue.js
  alt_file=node_modules/@vue/shared/package.json
  if [[ -e $file ]]; then
    [[ $(head -n 2 "$file") =~ $ver_pattern ]] && echo "vue ${BASH_REMATCH[1]}"
  elif [[ -e "$alt_file" ]]; then
    [[ $(grep version "$alt_file" | head -1) =~ $ver_pattern ]] && echo "vue ${BASH_REMATCH[1]}"
  fi
  echo -en "\e[0m"
}

# get_starter_env_val
# Description:
# Outputs a value for a key ($1) set in .starter.env
# Verbose error reporting for various edge cases
# and /var/log/workspace-init.log
#
# Usage (output will either be the value of the key or an error message):
# value="$(get_starter_env_value PHPMYADMIN_CONTROL_PW)"
# echo $value
get_starter_env_val() {
  local err='get_starter_env_val ERROR:'
  local file='.gp/.starter.env'
  local value
  value="$(bash .gp/bash/utils.sh get_env_value "$1" "$file")"
  case "$?" in
    '0')
      echo "$value"
      ;;

    '3')
      echo "$err no file: $file"
      exit 1
      ;;

    '4')
      echo -e "$err no variable '$1' found in file $file"
      exit 1
      ;;

    '5')
      echo "$err no value found for '$1' in file $file"
      exit 1
      ;;

    *)
      echo "$err unidentified error $?"
      exit 1
      ;;
  esac
}

get_server_port() {
  case $(echo "$1" | tr '[:upper:]' '[:lower:]') in
    'php')
      echo 8000
      ;;
    'apache')
      echo 8001
      ;;
    'nginx')
      echo 8002
      ;;
    *)
      exit 127
      ;;
  esac
}

get_default_server_port() {
  local server
  server=$(bash .gp/bash/utils.sh parse_ini_value starter.ini development default_server) ;
  get_server_port "$(echo "$server" | tr '[:upper:]' '[:lower:]')"
}

get_default_gp_url() {
  gp url "$(get_default_server_port)"
}

# Begin: persistance hacks
get_store_root() {
  echo "/workspace/$(basename "$GITPOD_REPO_ROOT")--store"
}

persist_file() {
  local err="helpers.sh: persist: error:"
  local store dest file
  store=$(get_store_root)
  dest="$store/$(dirname "${1#/}")"
  file="$dest/$(basename "$1")"
  mkdir -p "$store" && mkdir -p "$dest"
  [[ -f $1 ]] && cp "$1" "$file" || echo "$err $1 does not exist"
}

# For some reason $GITPOD_REPO_ROOT is not avaialable when this is called (from before task)
# So just pass it in from there as $1
restore_persistent_files() {
  local err="helpers.sh: restore_persistent_files: error:"
  # TODO make this dynamic
  local init_log_orig=/var/log/workspace-init.log
  local store
  store="/workspace/$(basename "$1")--store"
  local init_log="$store$init_log_orig"
  [[ -e $init_log ]] && cp "$init_log" $init_log_orig || echo "$err $init_log NOT FOUND"
}

inited_file () {
  echo "$(get_store_root)/is_inited.lock"
}

mark_as_inited() {
  local file store
  file=$(inited_file)
  store=$(get_store_root)
  mkdir -p "$(get_store_root)"
  [[ ! -e $file ]] && touch "$file"
}

is_inited() {
  [[ -e $(inited_file) ]] && echo 1 || echo 0
}
# End: persistance hacks

# php_fpm_conf
# Configures the php-fpm.conf depending on PHP version ($1) and the output file ($2)
# NOTE: If you want to configure this further parse the result of this from elsewhere.
php_fpm_conf() {
  [[ -z $1 || -z $2 ]] && 2>&1 echo "  ERROR: utils.sh --> php_fpm_conf(): Bad args. Script aborted" && exit 1
  echo "\
[global]
pid = /tmp/php$1-fpm.pid
error_log = /tmp/php$1-fpm.log

[www]
listen = 127.0.0.1:9000
listen.owner = gitpod
listen.group = gitpod

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3" > "$2"
}

# Call functions from this script gracefully
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  echo "helpers.sh: '$1' is not a known function name." >&2
  exit 1
fi