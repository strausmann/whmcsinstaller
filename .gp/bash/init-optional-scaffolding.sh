#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright © 2021 Apolo Pena
#
# init-optional-scaffolding.sh
# Description:
# Installs frontend scaffolding, optional EXAMPLES and other packages as per the values set in starter.ini

# Load logger
. .gp/bash/workspace-init-logger.sh

# Load spinner
. .gp/bash/spinner.sh

# Workaround third party sass bug: https://github.com/apolopena/gitpod-laravel-starter/issues/140
hotfix140 () {
  local exit_code msg="Applying hotfix 140"
  log_silent "$msg..." && start_spinner "$msg"
  yes | npx add-dependencies sass@1.32.12 --dev 2> >(grep -v warning 1>&2) > /dev/null 2>&1
  exit_code=$?
  if [[ $exit_code == 0 ]]; then
    stop_spinner 0
    log_silent "SUCCESS: $msg"
  else
    stop_spinner 1
    log_silent -e "ERROR: $msg"
  fi
}

parse="bash .gp/bash/utils.sh parse_ini_value starter.ini"

install_phpmyadmin=$(eval "$parse" phpmyadmin install)
init_phpmyadmin=".gp/bash/init-phpmyadmin.sh"

# Install phpMyAdmin if needed
if [[ $install_phpmyadmin == 1 ]];then
    # shellcheck source=.gp/bash/init-phpmyadmin.sh
    . "$init_phpmyadmin" 2>/dev/null || log_silent -e "ERROR: $(. $init_phpmyadmin 2>&1 1>/dev/null)"
fi