#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright © 2022 Apolo Pena
#
# init-gitpod.sh
# Description:
# Tasks to be run when a gitpod workspace is created for the first time.

# Load logger
. .gp/bash/workspace-init-logger.sh

# Load spinner
. .gp/bash/spinner.sh

# Let the user know there will be a wait, then begin once MySql is initialized.
start_spinner "Initializing MySql..." &&
gp await-port 3306 &&
stop_spinner $?

# Globals
current_php_version="$(bash .gp/bash/utils.sh php_version)"

# BEGIN: Install https://www.ioncube.com/loaders.php
if [[ $(bash .gp/bash/utils.sh parse_ini_value starter.ini ioncube install) == 1 ]]; then
  if [[ $current_php_version == 7.4 ]]; then
    msg="Installing ioncube loader"
    log_silent "$msg" && start_spinner "$msg" \
    && wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /tmp/ioncube.tar.gz \
    && tar xzf /tmp/ioncube.tar.gz -C /tmp \
    && sudo cp /tmp/ioncube/ioncube_loader_lin_7.4.so /usr/lib/php/20190902/ioncube_loader_lin_7.4.so \
    && sudo bash -c 'echo "zend_extension=ioncube_loader_lin_7.4.so" > /etc/php/7.4/apache2/conf.d/10-ioncube.ini' \
    && sudo bash -c 'echo "zend_extension=ioncube_loader_lin_7.4.so" > /etc/php/7.4/cli/conf.d/10-ioncube.ini' \
    && rm -rf /tmp/ioncube.tar.gz /tmp/ioncube
    err_code=$?
    if [[ $err_code != 0 ]]; then
      stop_spinner $err_code
      log -e "ERROR: $msg"
    else
      stop_spinner $err_code
      log "SUCCESS: $msg"
    fi
  else
    log "WARNING: ioncube loader cannot be installed with PHP $current_php_version. Fix your starter.ini"
  fi
fi
# END: Install https://www.ioncube.com/loaders.php

# BEGIN: Bootstrap non-laravel
if [[ ! -d $GITPOD_REPO_ROOT/routes ]]; then
  # BEGIN: Autogenerate php-fpm.conf
  php_fpm_conf_path=".gp/conf/php-fpm/php-fpm.conf"
  active_php_version="$(. .gp/bash/utils.sh php_version)"
  msg="Autogenerating $php_fpm_conf_path for PHP $active_php_version"
  log_silent "$msg" && start_spinner "$msg"
  if bash .gp/bash/helpers.sh php_fpm_conf "$active_php_version" "$php_fpm_conf_path"; then
    stop_spinner $?
    log_silent "SUCCESS: $msg"
  else
    stop_spinner $?
    log -e "ERROR: $msg"
  fi
  # END: Autogenerate php-fpm.conf

  # BEGIN: parse .vscode/settings.json
  if [[ $(bash .gp/bash/utils.sh parse_ini_value starter.ini development vscode_disable_preview_tab) == 1 ]]; then
    msg="parsing .vscode/settings.json as per starter.ini"
    log_silent "$msg" && start_spinner "$msg"
    if bash .gp/bash/utils.sh add_file_to_file_after '{' ".gp/conf/vscode/disable_preview_tab.txt" ".vscode/settings.json"; then
      stop_spinner $?
      log_silent "SUCCESS: $msg"
    else
      stop_spinner $?
      log -e "ERROR: $msg"
    fi
  fi
  # END: parse .vscode/settings.json
fi;
# END: Bootstrap non-laravel
