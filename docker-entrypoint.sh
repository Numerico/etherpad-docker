#!/bin/bash

# based on wordpress https://github.com/docker-library/wordpress/blob/1b48b4bccd7adb0f7ea1431c7b470a40e186f3da/docker-entrypoint.sh

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

envs=(
	ETHER_DB_HOST
	ETHER_DB_USER
	ETHER_DB_PASSWORD
	ETHER_DB_NAME
	ETHER_ADMIN_PASSWORD
)
haveConfig=
for e in "${envs[@]}"; do
		file_env "$e"
		if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
			haveConfig=1
		fi
done

if [ "$haveConfig" ]; then
		: "${ETHER_DB_HOST:=mysql}"
		: "${ETHER_DB_USER:=root}"
		: "${ETHER_DB_PASSWORD:=}"
		: "${ETHER_DB_NAME:=store}"
		: "${ETHER_ADMIN_PASSWORD:=}"

		set_config() {
			key="$1"
			value="$2"
			sed -i "s/\$$key/$value/g" settings.json
		}

		set_config 'ETHER_DB_HOST' "$ETHER_DB_HOST"
		set_config 'ETHER_DB_USER' "$ETHER_DB_USER"
		set_config 'ETHER_DB_PASSWORD' "$ETHER_DB_PASSWORD"
		set_config 'ETHER_DB_NAME' "$ETHER_DB_NAME"
		set_config 'ETHER_ADMIN_PASSWORD' "$ETHER_ADMIN_PASSWORD"

	for e in "${envs[@]}"; do
		unset "$e"
	done
fi

# actual entrypoint
supervisord -c /etc/supervisor/supervisor.conf -n
