#!/bin/bash

HOME_DIR='/home/docker'

# Copy Acquia Cloud API credentials
# @param $1 path to the home directory (parent of the .acquia directory)
copy_dot_acquia ()
{
  local path="${1}/.acquia/cloudapi.conf"
  if [[ -f ${path} ]]; then
    echo "Copying Acquia Cloud API settings in ${path} from host..."
    mkdir -p ${HOME_DIR}/.acquia
    cp ${path} ${HOME_DIR}/.acquia
  fi
}

# Copy Drush settings from host
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_drush ()
{
  local path="${1}/.drush"
  if [[ -d ${path} ]]; then
    echo "Copying Drush settigns in ${path} from host..."
    cp -r ${path} ${HOME_DIR}
  fi
}

# Copy Acquia Cloud API credentials and Drush settings from host if available
copy_dot_acquia '/.home' # Generic
copy_dot_drush '/.home' # Generic

## Docker user uid/gid mapping to the host user uid/gid
if [[ "$HOST_UID" != "" ]] && [[ "$HOST_GID" != "" ]]; then
	if [[ "$HOST_UID" != "$(id -u docker)" ]] || [[ "$HOST_GID" != "$(id -g docker)" ]]; then
		echo "Updating docker user uid/gid to $HOST_UID/$HOST_GID to match the host user uid/gid..."
		sudo groupmod -g "$HOST_GID" -o users
		sudo usermod -u "$HOST_UID" -g "$HOST_GID" -o docker
		# Make sure permissions are correct after the uid/gid change
		sudo chown "$HOST_UID:$HOST_GID" -R ${HOME_DIR}
		sudo chown "$HOST_UID:$HOST_GID" /var/www
	fi
fi

# Enable xdebug
if [[ "${XDEBUG_ENABLED}" == "1" ]]; then
  echo "Enabling xdebug..."
  sudo php5enmod xdebug
fi

# Execute passed CMD arguments
if [[ "$1" == "supervisord" ]]; then
	gosu root supervisord
else
	gosu docker "$@"
fi
