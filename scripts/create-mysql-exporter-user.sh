#!/bin/sh
set -eu

if [ -z "${MYSQL_ROOT_PASSWORD:-}" ] || [ -z "${MYSQL_EXPORTER_USER:-}" ] || [ -z "${MYSQL_EXPORTER_PASSWORD:-}" ]; then
    echo "Required MySQL exporter credentials are missing." >&2
    exit 1
fi

case "$MYSQL_EXPORTER_USER" in
    *[!a-zA-Z0-9_]*)
        echo "MYSQL_EXPORTER_USER may contain only letters, digits, and underscores." >&2
        exit 1
        ;;
esac

if [ "${#MYSQL_EXPORTER_PASSWORD}" -ne 64 ]; then
    echo "MYSQL_EXPORTER_PASSWORD must be a 64-character hex value; generate one with openssl rand -hex 32." >&2
    exit 1
fi

case "$MYSQL_EXPORTER_PASSWORD" in
    *[!a-fA-F0-9]*)
        echo "MYSQL_EXPORTER_PASSWORD must be hexadecimal." >&2
        exit 1
        ;;
esac

MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mariadb --user=root <<SQL
CREATE USER IF NOT EXISTS '${MYSQL_EXPORTER_USER}'@'%' IDENTIFIED BY '${MYSQL_EXPORTER_PASSWORD}' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '${MYSQL_EXPORTER_USER}'@'%';
FLUSH PRIVILEGES;
SQL
