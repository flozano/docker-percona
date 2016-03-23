#!/bin/bash
set -eo pipefail

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = "-" ]; then
    set -- mysqld "$@"
fi

# skip setup if they want an option that stops mysqld
wantHelp=
for arg; do
    case "$arg" in
	-"?"|--help|--print-defaults|-V|--version)
	    wantHelp=1
	break
	;;
    esac
done

check_conf() {
    echo $(mysqld --verbose --help 1>/dev/null)
}

write_conf() {
    if [ "$1" -a "$2" ]; then
	echo -n " - checking and writing $1"
	echo $1 >> $2
	check_conf
    fi
}

write_conf_value() {
    if [ "$1" -a "$2" -a "$3" ]; then
	echo -n " - checking and writing $1 = $2"
	echo $1" = "$2 >> $3
	check_conf
    fi
}


if [ "$1" = "mysqld" -a -z "$wantHelp" ]; then
    # Get config
    DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"

    if [ ! -f /etc/mysql/conf.d/mysqld.cnf ]; then
	echo "Creating /etc/mysql/conf.d/mysqld.cnf from environment parameters ..."
	echo "[mysqld]" > /etc/mysql/conf.d/mysqld.cnf
	if [ -z "$MYSQL_MYSQLD_USER" ]; then
	    MYSQL_MYSQLD_USER="mysql"
	fi
	chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} /etc/mysql
	write_conf_value "user" "$MYSQL_MYSQLD_USER" "/etc/mysql/conf.d/mysqld.cnf"

	if [ -z "$MYSQL_MYSQLD_DATADIR" ]; then
	    MYSQL_MYSQLD_DATADIR="$DATADIR"
	else
	    write_conf_value "datadir" "$MYSQL_MYSQLD_DATADIR" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 "$MYSQL_MYSQLD_DATADIR" && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} "$MYSQL_MYSQLD_DATADIR"
	fi

	if [ -z "$MYSQL_MYSQLD_BIND_ADDRESS" ]; then
	    MYSQL_MYSQLD_BIND_ADDRESS="$("$@" --verbose --help 2>/dev/null | awk '$1 == "bind-address" { print $2; exit }')"
	else
	    write_conf_value "bind-address" "$MYSQL_MYSQLD_BIND_ADDRESS" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_SERVER_ID" ]; then
	    echo " - using default MYSQL_MYSQLD_SERVER_ID for single master-slave architecture!"
	    if [ -n "$REPLICATION_SLAVE" ]; then
	        MYSQL_MYSQLD_SERVER_ID=2
	    else
	        MYSQL_MYSQLD_SERVER_ID=1
	    fi
	    write_conf_value "server-id" "$MYSQL_MYSQLD_SERVER_ID" "/etc/mysql/conf.d/mysqld.cnf"
	else
	    write_conf_value "server-id" "$MYSQL_MYSQLD_SERVER_ID" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_SQL_MODE" ]; then
	    MYSQL_MYSQLD_SQL_MODE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "sql-mode" { print $2; exit }')"
	else
	    write_conf_value "sql-mode" "$MYSQL_MYSQLD_SQL_MODE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_BASEDIR" ]; then
	    MYSQL_MYSQLD_BASEDIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "basedir" { print $2; exit }')"
	else
	    write_conf_value "basedir" "$MYSQL_MYSQLD_BASEDIR" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_DATA_HOME_DIR" ]; then
	    MYSQL_MYSQLD_INNODB_DATA_HOME_DIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_data_home_dir" { print $2; exit }')"
	else
	    write_conf_value "innodb_data_home_dir" "$MYSQL_MYSQLD_INNODB_DATA_HOME_DIR" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 "$MYSQL_MYSQLD_INNODB_DATA_HOME_DIR" && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} "$MYSQL_MYSQLD_INNODB_DATA_HOME_DIR"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_LOG_GROUP_HOME_DIR" ]; then
	    MYSQL_MYSQLD_INNODB_LOG_GROUP_HOME_DIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_log_group_home_dir" { print $2; exit }')"
	else
	    write_conf_value "innodb_log_group_home_dir" "$MYSQL_MYSQLD_INNODB_LOG_GROUP_HOME_DIR" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 "$MYSQL_MYSQLD_INNODB_LOG_GROUP_HOME_DIR" && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} "$MYSQL_MYSQLD_INNODB_LOG_GROUP_HOME_DIR"
	fi

	# need for GTID'ed slave 
	if [ -z "$MYSQL_MYSQLD_LOG_BIN" ]; then
	    MYSQL_MYSQLD_LOG_BIN="$("$@" --verbose --help 2>/dev/null | awk '$1 == "log-bin" { print $2; exit }')"
	else
	    write_conf_value "log-bin" "$MYSQL_MYSQLD_LOG_BIN" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_LOG_BIN") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_LOG_BIN")
	fi

	if [ -z "$MYSQL_MYSQLD_LOG_ERROR" ]; then
	    MYSQL_MYSQLD_LOG_ERROR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "log-error" { print $2; exit }')"
	else
	    write_conf_value "log-error" "$MYSQL_MYSQLD_LOG_ERROR" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_LOG_ERROR") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_LOG_ERROR")
	fi

	if [ -z "$MYSQL_MYSQLD_MASTER_INFO_FILE" ]; then
	    MYSQL_MYSQLD_MASTER_INFO_FILE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "master_info_file" { print $2; exit }')"
	else
	    write_conf_value "master_info_file" "$MYSQL_MYSQLD_MASTER_INFO_FILE" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_MASTER_INFO_FILE") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_MASTER_INFO_FILE")
	fi

	if [ -z "$MYSQL_MYSQLD_PID_FILE" ]; then
	    MYSQL_MYSQLD_PID_FILE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "pid-file" { print $2; exit }')"
	else
	    write_conf_value "pid-file" "$MYSQL_MYSQLD_PID_FILE" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_PID_FILE") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_PID_FILE")
	fi

	if [ -z "$MYSQL_MYSQLD_RELAY_LOG" ]; then
	    MYSQL_MYSQLD_RELAY_LOG="$("$@" --verbose --help 2>/dev/null | awk '$1 == "relay_log" { print $2; exit }')"
	else
	    write_conf_value "relay_log" "$MYSQL_MYSQLD_RELAY_LOG" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_RELAY_LOG") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_RELAY_LOG")
	fi

	if [ -z "$MYSQL_MYSQLD_RELAY_LOG_INFO_FILE" ]; then
	    MYSQL_MYSQLD_RELAY_LOG_INFO_FILE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "relay_log_info_file" { print $2; exit }')"
	else
	    write_conf_value "relay_log_info_file" "$MYSQL_MYSQLD_RELAY_LOG_INFO_FILE" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_RELAY_LOG_INFO_FILE") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_RELAY_LOG_INFO_FILE")
	fi

	if [ -z "$MYSQL_MYSQLD_RELAY_LOG_INDEX" ]; then
	    MYSQL_MYSQLD_RELAY_LOG_INDEX="$("$@" --verbose --help 2>/dev/null | awk '$1 == "relay_log_index" { print $2; exit }')"
	else
	    write_conf_value "relay_log_index" "$MYSQL_MYSQLD_RELAY_LOG_INDEX" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_RELAY_LOG_INDEX") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_RELAY_LOG_INDEX")
	fi

	if [ -z "$MYSQL_MYSQLD_SLOW_QUERY_LOG" ]; then
	    MYSQL_MYSQLD_SLOW_QUERY_LOG="$("$@" --verbose --help 2>/dev/null | awk '$1 == "slow_query_log" { print $2; exit }')"
	else
	    write_conf_value "slow_query_log" "$MYSQL_MYSQLD_SLOW_QUERY_LOG" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_SLOW_QUERY_LOG_FILE" ]; then
	    MYSQL_MYSQLD_SLOW_QUERY_LOG_FILE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "slow_query_log_file" { print $2; exit }')"
	else
	    write_conf_value "slow_query_log_file" "$MYSQL_MYSQLD_SLOW_QUERY_LOG_FILE" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_SLOW_QUERY_LOG_FILE") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_SLOW_QUERY_LOG_FILE")
	fi

	if [ -z "$MYSQL_MYSQLD_SOCKET" ]; then
	    MYSQL_MYSQLD_SOCKET="$("$@" --verbose --help 2>/dev/null | awk '$1 == "socket" { print $2; exit }')"
	else
	    write_conf_value "socket" "$MYSQL_MYSQLD_SOCKET" "/etc/mysql/conf.d/mysqld.cnf"
	    mkdir -p -m 0750 $(dirname "$MYSQL_MYSQLD_SOCKET") && chown -R ${MYSQL_MYSQLD_USER}:${MYSQL_MYSQLD_USER} $(dirname "$MYSQL_MYSQLD_SOCKET")
	fi

	if [ -z "$MYSQL_MYSQLD_TMPDIR" ]; then
	    MYSQL_MYSQLD_TMPDIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "tmpdir" { print $2; exit }')"
	else
	    write_conf_value "tmpdir" "$MYSQL_MYSQLD_TMPDIR" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	# need for GTIDed slave
	if [ -z "$MYSQL_MYSQLD_LOG_SLAVE_UPDATES" ]; then
	    MYSQL_MYSQLD_LOG_SLAVE_UPDATES="$("$@" --verbose --help 2>/dev/null | awk '$1 == "log-slave-updates" { print $2; exit }')"
	else
	    write_conf_value "log-slave-updates" "$MYSQL_MYSQLD_LOG_SLAVE_UPDATES" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_EXPIRE_LOGS_DAYS" ]; then
	    MYSQL_MYSQLD_EXPIRE_LOGS_DAYS="$("$@" --verbose --help 2>/dev/null | awk '$1 == "expire_logs_days" { print $2; exit }')"
	else
	    write_conf_value "expire_logs_days" "$MYSQL_MYSQLD_EXPIRE_LOGS_DAYS" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_BINLOG_CHECKSUM" ]; then
	    MYSQL_MYSQLD_BINLOG_CHECKSUM="$("$@" --verbose --help 2>/dev/null | awk '$1 == "binlog-checksum" { print $2; exit }')"
	else
	    write_conf_value "binlog-checksum" "$MYSQL_MYSQLD_BINLOG_CHECKSUM" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_GTID_MODE" ]; then
	    MYSQL_MYSQLD_GTID_MODE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "gtid-mode" { print $2; exit }')"
	else
	    write_conf_value "gtid-mode" "$MYSQL_MYSQLD_GTID_MODE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_ENFORCE_GTID_CONSISTENCY" ]; then
	    MYSQL_MYSQLD_ENFORCE_GTID_CONSISTENCY="$("$@" --verbose --help 2>/dev/null | awk '$1 == "enforce-gtid-consistency" { print $2; exit }')"
	else
	    write_conf_value "enforce-gtid-consistency" "$MYSQL_MYSQLD_ENFORCE_GTID_CONSISTENCY" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_SYNC_BINLOG" ]; then
	    MYSQL_MYSQLD_SYNC_BINLOG="$("$@" --verbose --help 2>/dev/null | awk '$1 == "sync_binlog" { print $2; exit }')"
	else
	    write_conf_value "sync_binlog" "$MYSQL_MYSQLD_SYNC_BINLOG" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_REPLICATE_DO_DB" ]; then
	    MYSQL_MYSQLD_REPLICATE_DO_DB="$("$@" --verbose --help 2>/dev/null | awk '$1 == "replicate-do-db" { print $2; exit }')"
	else
	    write_conf_value "replicate-do-db" "$MYSQL_MYSQLD_REPLICATE_DO_DB" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_BINLOG_IGNORE_DB" ]; then
	    MYSQL_MYSQLD_BINLOG_IGNORE_DB="$("$@" --verbose --help 2>/dev/null | awk '$1 == "binlog-ignore-db" { print $2; exit }')"
	else
	    write_conf_value "binlog-ignore-db" "$MYSQL_MYSQLD_BINLOG_IGNORE_DB" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_BINLOG_ROW_EVENT_MAX_SIZE" ]; then
	    MYSQL_MYSQLD_BINLOG_ROW_EVENT_MAX_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "binlog-row-event-max-size" { print $2; exit }')"
	else
	    write_conf_value "binlog-row-event-max-size" "$MYSQL_MYSQLD_BINLOG_ROW_EVENT_MAX_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_BINLOG_FORMAT" ]; then
	    MYSQL_MYSQLD_BINLOG_FORMAT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "binlog-format" { print $2; exit }')"
	else
	    write_conf_value "binlog-format" "$MYSQL_MYSQLD_BINLOG_FORMAT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ ! -z "$MYSQL_MYSQLD_LARGE_PAGES" ]; then
	    write_conf "large_pages" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ ! -z "$MYSQL_MYSQLD_SKIP_NAME_RESOLVE" ]; then
	    write_conf "skip_name_resolve" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ ! -z "$MYSQL_MYSQLD_SKIP_HOST_CACHE" ]; then
	    write_conf "skip_host_cache" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ ! -z "$MYSQL_MYSQLD_SKIP_EXTERNAL_LOCKING" ]; then
	    write_conf "skip_external_locking" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ ! -z "$MYSQL_MYSQLD_SKIP_INNODB_DOUBLEWRITE" ]; then
	    write_conf "skip_innodb_doublewrite" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_SYMBOLIC_LINKS" ]; then
	    MYSQL_MYSQLD_SYMBOLIC_LINKS="$("$@" --verbose --help 2>/dev/null | awk '$1 == "symbolic-links" { print $2; exit }')"
	else
	    write_conf_value "symbolic-links" "$MYSQL_MYSQLD_SYMBOLIC_LINKS" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_EVENT_SCHEDULER" ]; then
	    MYSQL_MYSQLD_EVENT_SCHEDULER="$("$@" --verbose --help 2>/dev/null | awk '$1 == "event_scheduler" { print $2; exit }')"
	else
	    write_conf_value "event_scheduler" "$MYSQL_MYSQLD_EVENT_SCHEDULER" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_DEFAULT_STORAGE_ENGINE" ]; then
	    MYSQL_MYSQLD_DEFAULT_STORAGE_ENGINE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "default_storage_engine" { print $2; exit }')"
	else
	    write_conf_value "default_storage_engine" "$MYSQL_MYSQLD_DEFAULT_STORAGE_ENGINE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_CHARACTER_SET_SERVER" ]; then
	    MYSQL_MYSQLD_CHARACTER_SET_SERVER="$("$@" --verbose --help 2>/dev/null | awk '$1 == "character_set_server" { print $2; exit }')"
	else
	    write_conf_value "character_set_server" "$MYSQL_MYSQLD_CHARACTER_SET_SERVER" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_COLLATION_SERVER" ]; then
	    MYSQL_MYSQLD_COLLATION_SERVER="$("$@" --verbose --help 2>/dev/null | awk '$1 == "collation-server" { print $2; exit }')"
	else
	    write_conf_value "collation-server" "$MYSQL_MYSQLD_COLLATION_SERVER" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INIT_CONNECT" ]; then
	    MYSQL_MYSQLD_INIT_CONNECT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "init_connect" { print $2; exit }')"
	else
	    write_conf_value "init_connect" "$MYSQL_MYSQLD_INIT_CONNECT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_CONNECT_TIMEOUT" ]; then
	    MYSQL_MYSQLD_CONNECT_TIMEOUT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "connect_timeout" { print $2; exit }')"
	else
	    write_conf_value "connect_timeout" "$MYSQL_MYSQLD_CONNECT_TIMEOUT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_WAIT_TIMEOUT" ]; then
	    MYSQL_MYSQLD_WAIT_TIMEOUT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "wait_timeout" { print $2; exit }')"
	else
	    write_conf_value "wait_timeout" "$MYSQL_MYSQLD_WAIT_TIMEOUT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_MAX_CONNECTIONS" ]; then
	    MYSQL_MYSQLD_MAX_CONNECTIONS="$("$@" --verbose --help 2>/dev/null | awk '$1 == "max_connections" { print $2; exit }')"
	else
	    write_conf_value "max_connections" "$MYSQL_MYSQLD_MAX_CONNECTIONS" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_MAX_ALLOWED_PACKET" ]; then
	    MYSQL_MYSQLD_MAX_ALLOWED_PACKET="$("$@" --verbose --help 2>/dev/null | awk '$1 == "max_allowed_packet" { print $2; exit }')"
	else
	    write_conf_value "max_allowed_packet" "$MYSQL_MYSQLD_MAX_ALLOWED_PACKET" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_MAX_CONNECT_ERRORS" ]; then
	    MYSQL_MYSQLD_MAX_CONNECT_ERRORS="$("$@" --verbose --help 2>/dev/null | awk '$1 == "max_connect_errors" { print $2; exit }')"
	else
	    write_conf_value "max_connect_errors" "$MYSQL_MYSQLD_MAX_CONNECT_ERRORS" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_NET_READ_TIMEOUT" ]; then
	    MYSQL_MYSQLD_NET_READ_TIMEOUT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "net_read_timeout" { print $2; exit }')"
	else
	    write_conf_value "net_read_timeout" "$MYSQL_MYSQLD_NET_READ_TIMEOUT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_NET_WRITE_TIMEOUT" ]; then
	    MYSQL_MYSQLD_NET_WRITE_TIMEOUT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "net_write_timeout" { print $2; exit }')"
	else
	    write_conf_value "net_write_timeout" "$MYSQL_MYSQLD_NET_WRITE_TIMEOUT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_LOG_QUERIES_NOT_USING_INDEXES" ]; then
	    MYSQL_MYSQLD_LOG_QUERIES_NOT_USING_INDEXES="$("$@" --verbose --help 2>/dev/null | awk '$1 == "log-queries-not-using-indexes" { print $2; exit }')"
	else
	    write_conf_value "log-queries-not-using-indexes" "$MYSQL_MYSQLD_LOG_QUERIES_NOT_USING_INDEXES" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_TRANSACTION_ISOLATION" ]; then
	    MYSQL_MYSQLD_TRANSACTION_ISOLATION="$("$@" --verbose --help 2>/dev/null | awk '$1 == "transaction-isolation" { print $2; exit }')"
	else
	    write_conf_value "transaction-isolation" "$MYSQL_MYSQLD_TRANSACTION_ISOLATION" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_LC_MESSAGES_DIR" ]; then
	    MYSQL_MYSQLD_LC_MESSAGES_DIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "lc-messages-dir" { print $2; exit }')"
	else
	    write_conf_value "lc-messages-dir" "$MYSQL_MYSQLD_LC_MESSAGES_DIR" "/etc/mysql/conf.d/mysqld.cnf"
	fi


	if [ -z "$MYSQL_MYSQLD_INNODB_FILE_PER_TABLE" ]; then
	    MYSQL_MYSQLD_INNODB_FILE_PER_TABLE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_file_per_table" { print $2; exit }')"
	else
	    write_conf_value "innodb_file_per_table" "$MYSQL_MYSQLD_INNODB_FILE_PER_TABLE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_OPEN_FILES" ]; then
	    MYSQL_MYSQLD_INNODB_OPEN_FILES="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_open_files" { print $2; exit }')"
	else
	    write_conf_value "innodb_open_files" "$MYSQL_MYSQLD_INNODB_OPEN_FILES" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_BUFFER_POOL_SIZE" ]; then
	    MYSQL_MYSQLD_INNODB_BUFFER_POOL_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_buffer_pool_size" { print $2; exit }')"
	else
	    write_conf_value "innodb_buffer_pool_size" "$MYSQL_MYSQLD_INNODB_BUFFER_POOL_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_BUFFER_POOL_INSTANCES" ]; then
	    MYSQL_MYSQLD_INNODB_BUFFER_POOL_INSTANCES="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_buffer_pool_instances" { print $2; exit }')"
	else
	    write_conf_value "innodb_buffer_pool_instances" "$MYSQL_MYSQLD_INNODB_BUFFER_POOL_INSTANCES" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_FLUSH_LOG_AT_TRX_COMMIT" ]; then
	    MYSQL_MYSQLD_INNODB_FLUSH_LOG_AT_TRX_COMMIT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_flush_log_at_trx_commit" { print $2; exit }')"
	else
	    write_conf_value "innodb_flush_log_at_trx_commit" "$MYSQL_MYSQLD_INNODB_FLUSH_LOG_AT_TRX_COMMIT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_FLUSH_METHOD" ]; then
	    MYSQL_MYSQLD_INNODB_FLUSH_METHOD="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_flush_method" { print $2; exit }')"
	else
	    write_conf_value "innodb_flush_method" "$MYSQL_MYSQLD_INNODB_FLUSH_METHOD" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_LOG_BUFFER_SIZE" ]; then
	    MYSQL_MYSQLD_INNODB_LOG_BUFFER_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_log_buffer_size" { print $2; exit }')"
	else
	    write_conf_value "innodb_log_buffer_size" "$MYSQL_MYSQLD_INNODB_LOG_BUFFER_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_AUTOEXTEND_INCREMENT" ]; then
	    MYSQL_MYSQLD_INNODB_AUTOEXTEND_INCREMENT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_autoextend_increment" { print $2; exit }')"
	else
	    write_conf_value "innodb_autoextend_increment" "$MYSQL_MYSQLD_INNODB_AUTOEXTEND_INCREMENT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_CONCURRENCY_TICKETS" ]; then
	    MYSQL_MYSQLD_INNODB_CONCURRENCY_TICKETS="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_concurrency_tickets" { print $2; exit }')"
	else
	    write_conf_value "innodb_concurrency_tickets" "$MYSQL_MYSQLD_INNODB_CONCURRENCY_TICKETS" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_DATA_FILE_PATH" ]; then
	    MYSQL_MYSQLD_INNODB_DATA_FILE_PATH="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_data_file_path" { print $2; exit }')"
	else
	    write_conf_value "innodb_data_file_path" "$MYSQL_MYSQLD_INNODB_DATA_FILE_PATH" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_LOG_FILES_IN_GROUP" ]; then
	    MYSQL_MYSQLD_INNODB_LOG_FILES_IN_GROUP="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_log_files_in_group" { print $2; exit }')"
	else
	    write_conf_value "innodb_log_files_in_group" "$MYSQL_MYSQLD_INNODB_LOG_FILES_IN_GROUP" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_OLD_BLOCKS_TIME" ]; then
	    MYSQL_MYSQLD_INNODB_OLD_BLOCKS_TIME="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_old_blocks_time" { print $2; exit }')"
	else
	    write_conf_value "innodb_old_blocks_time" "$MYSQL_MYSQLD_INNODB_OLD_BLOCKS_TIME" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_STATS_ON_METADATA" ]; then
	    MYSQL_MYSQLD_INNODB_STATS_ON_METADATA="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_stats_on_metdata" { print $2; exit }')"
	else
	    write_conf_value "innodb_stats_on_metadata" "$MYSQL_MYSQLD_INNODB_STATS_ON_METADATA" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_FAST_SHUTDOWN" ]; then
	    MYSQL_MYSQLD_INNODB_FAST_SHUTDOWN="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_fast_shutdown" { print $2; exit }')"
	else
	    write_conf_value "innodb_fast_shutdown" "$MYSQL_MYSQLD_INNODB_FAST_SHUTDOWN" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_INNODB_LOG_FILE_SIZE" ]; then
	    MYSQL_MYSQLD_INNODB_LOG_FILE_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "innodb_log_file_size" { print $2; exit }')"
	else
	    write_conf_value "innodb_log_file_size" "$MYSQL_MYSQLD_INNODB_LOG_FILE_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_PERFORMANCE_SCHEMA" ]; then
	    MYSQL_MYSQLD_PERFORMANCE_SCHEMA="$("$@" --verbose --help 2>/dev/null | awk '$1 == "performance_schema" { print $2; exit }')"
	else
	    write_conf_value "performance_schema" "$MYSQL_MYSQLD_PERFORMANCE_SCHEMA" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_EXPLICIT_DEFAULTS_FOR_TIMESTAMP" ]; then
	    MYSQL_MYSQLD_EXPLICIT_DEFAULTS_FOR_TIMESTAMP="$("$@" --verbose --help 2>/dev/null | awk '$1 == "explicit_defaults_for_timestamp" { print $2; exit }')"
	else
	    write_conf_value "explicit_defaults_for_timestamp" "$MYSQL_MYSQLD_EXPLICIT_DEFAULTS_FOR_TIMESTAMP" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_QUERY_CACHE_SIZE" ]; then
	    MYSQL_MYSQLD_QUERY_CACHE_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "query_cache_size" { print $2; exit }')"
	else
	    write_conf_value "query_cache_size" "$MYSQL_MYSQLD_QUERY_CACHE_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_QUERY_CACHE_TYPE" ]; then
	    MYSQL_MYSQLD_QUERY_CACHE_TYPE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "query_cache_type" { print $2; exit }')"
	else
	    write_conf_value "query_cache_type" "$MYSQL_MYSQLD_QUERY_CACHE_TYPE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_QUERY_CACHE_MIN_RES_UNIT" ]; then
	    MYSQL_MYSQLD_QUERY_CACHE_MIN_RES_UNIT="$("$@" --verbose --help 2>/dev/null | awk '$1 == "query_cache_min_res_unit" { print $2; exit }')"
	else
	    write_conf_value "query_cache_min_res_unit" "$MYSQL_MYSQLD_QUERY_CACHE_MIN_RES_UNIT" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_JOIN_BUFFER_SIZE" ]; then
	    MYSQL_MYSQLD_JOIN_BUFFER_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "join_buffer_size" { print $2; exit }')"
	else
	    write_conf_value "join_buffer_size" "$MYSQL_MYSQLD_JOIN_BUFFER_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_READ_RND_BUFFER_SIZE" ]; then
	    MYSQL_MYSQLD_READ_RND_BUFFER_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "read_rnd_buffer_size" { print $2; exit }')"
	else
	    write_conf_value "read_rnd_buffer_size" "$MYSQL_MYSQLD_READ_RND_BUFFER_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_TABLE_DEFINITION_CACHE" ]; then
	    MYSQL_MYSQLD_TABLE_DEFINITION_CACHE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "table_definition_cache" { print $2; exit }')"
	else
	    write_conf_value "table_definition_cache" "$MYSQL_MYSQLD_TABLE_DEFINITION_CACHE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_TABLE_OPEN_CACHE" ]; then
	    MYSQL_MYSQLD_TABLE_OPEN_CACHE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "table_open_cache" { print $2; exit }')"
	else
	    write_conf_value "table_open_cache" "$MYSQL_MYSQLD_TABLE_OPEN_CACHE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_THREAD_CACHE_SIZE" ]; then
	    MYSQL_MYSQLD_THREAD_CACHE_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "thread_cache_size" { print $2; exit }')"
	else
	    write_conf_value "thread_cache_size" "$MYSQL_MYSQLD_THREAD_CACHE_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_TMP_TABLE_SIZE" ]; then
	    MYSQL_MYSQLD_TMP_TABLE_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "tmp_table_size" { print $2; exit }')"
	else
	    write_conf_value "tmp_table_size" "$MYSQL_MYSQLD_TMP_TABLE_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_MAX_HEAP_TABLE_SIZE" ]; then
	    MYSQL_MYSQLD_MAX_HEAP_TABLE_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "max_heap_table_size" { print $2; exit }')"
	else
	    write_conf_value "max_heap_table_size" "$MYSQL_MYSQLD_MAX_HEAP_TABLE_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_THREAD_HANDLING" ]; then
	    MYSQL_MYSQLD_THREAD_HANDLING="$("$@" --verbose --help 2>/dev/null | awk '$1 == "thread_handling" { print $2; exit }')"
	else
	    write_conf_value "thread_handling" "$MYSQL_MYSQLD_THREAD_HANDLING" "/etc/mysql/conf.d/mysqld.cnf"
	fi

	if [ -z "$MYSQL_MYSQLD_THREAD_POOL_SIZE" ]; then
	    MYSQL_MYSQLD_THREAD_POOL_SIZE="$("$@" --verbose --help 2>/dev/null | awk '$1 == "thread_pool_size" { print $2; exit }')"
	else
	    write_conf_value "thread_pool_size" "$MYSQL_MYSQLD_THREAD_POOL_SIZE" "/etc/mysql/conf.d/mysqld.cnf"
	fi
    fi

    # New install?
    if [ ! -d "$DATADIR/mysql" ]; then	

	echo "Initializing database ..."

	# Yes!
	if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
	    echo >&2 "error: database is uninitialized and password option is not specified "
	    echo >&2 "  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD"
	    exit 1
	fi

	# Create base directory structure from any *.tar.gz
	for f in /docker-entrypoint-initdb.d/*; do
	    case "$f" in
		*.tar.gz) echo "$0: extracting $f to /"; tar -xf "$f" -C /; echo ;;
	    esac
	done

	"$@" --initialize-insecure
	echo "Initialization successfully completed."

	"$@" --skip-networking &
	pid="$!"

	mysql=( mysql --protocol=socket -uroot )


	for i in 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00; do
	    if echo "SELECT 1" | "${mysql[@]}" &> /dev/null; then
		break
	    fi
	    echo "Waiting for starting MySQL in restricted mode ..."
	    sleep 1
	done
	if [ "$i" = 0 ]; then
	    echo >&2 "Waiting for starting MySQL in restricted mode failed."
	    exit 2
	fi

	echo "MySQL started in restricted mode."

	if [ -n "${REPLICATION_SLAVE}" ]; then
	    echo " - Configuring MySQL replication as slave ..."
	    if [ -z "${MYSQL_MASTER_ADDR}" ]; then
		MYSQL_MASTER_ADDR=mysql
	    fi

	    if [ -z "${MYSQL_MASTER_PORT}" ]; then
		MYSQL_MASTER_PORT=3306
	    fi


	    if [ -n "${MYSQL_MASTER_ADDR}" ] && [ -n "${MYSQL_MASTER_PORT}" ]; then
		if [ ! -f /tmp/.replication ]; then
		    echo " - Setting master connection info on slave"
		    "${mysql[@]}" <<-EOSQL
			SET @@SESSION.SQL_LOG_BIN=0;
			CHANGE MASTER TO MASTER_HOST='${MYSQL_MASTER_ADDR}', MASTER_AUTO_POSITION=1, MASTER_USER='${MYSQL_REPLICATION_USER}', MASTER_PASSWORD='${MYSQL_REPLICATION_PASS}', MASTER_PORT=${MYSQL_MASTER_PORT}, MASTER_CONNECT_RETRY=30;
			START SLAVE;
EOSQL
		    touch /tmp/.replication
		else
		    echo " - MySQL replication slave already configured, skip"
		fi
	    else
		echo " - Cannot configure slave, please link it to another MySQL container with alias as 'mysql'"
		exit 3
	    fi
	fi

	if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
	    # sed is for https://bugs.mysql.com/bug.php?id=20545
	    mysql_tzinfo_to_sql /usr/share/zoneinfo | sed "s/Local time zone must be set--see zic manual page/FCTY/" | "${mysql[@]}" mysql
	fi

	if [ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
	    MYSQL_ROOT_PASSWORD="$(pwgen -1 32)"
	    echo "Reset new root password to $MYSQL_ROOT_PASSWORD"
	fi
	"${mysql[@]}" <<-EOSQL
	    SET @@SESSION.SQL_LOG_BIN=0;
	    DELETE FROM mysql.user ;
	    CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
	    GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
	    DROP DATABASE IF EXISTS test;
	    FLUSH PRIVILEGES;
EOSQL

	if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
	    mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
	fi

	# Set MySQL REPLICATION - MASTER
	if [ -n "${REPLICATION_MASTER}" ]; then
	    echo " - Configuring MySQL replication as master ..."
	    if [ ! -f /tmp/.replication ]; then


		echo "   - Creating a log user ${REPLICATION_USER}:${REPLICATION_PASS}"

		"${mysql[@]}" <<-EOSQL
		    SET @@SESSION.SQL_LOG_BIN=0;
		    CREATE USER '${MYSQL_REPLICATION_USER}'@'%' IDENTIFIED BY '${MYSQL_REPLICATION_PASS}';
		    GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_REPLICATION_USER}'@'%';
		    FLUSH PRIVILEGES;
		    RESET MASTER;
EOSQL

		touch /tmp/.replication
	    else
		echo " - MySQL replication master already configured, skip"
	    fi

	    if [ "$MYSQL_DATABASE" ]; then
		echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;" | "${mysql[@]}"
		mysql+=( "$MYSQL_DATABASE" )
	    fi

	    if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
		echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" | "${mysql[@]}"

		if [ "$MYSQL_DATABASE" ]; then
		    echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';" | "${mysql[@]}"
		fi
		    echo "FLUSH PRIVILEGES;" | "${mysql[@]}"
	    fi
	fi

	echo
	for f in /docker-entrypoint-initdb.d/*; do
	    case "$f" in
		*.sh)     echo "$0: running $f"; . "$f" ;;
		*.sql)    echo "$0: running $f"; "${mysql[@]}" < "$f"; echo ;;
		*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | "${mysql[@]}"; echo ;;
		*) ;;
	    esac
	    echo
	done

	if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
	    "${mysql[@]}" <<-EOSQL
		ALTER USER 'root'@'%' PASSWORD EXPIRE;
EOSQL
	fi

	if ! kill -s TERM "$pid" || ! wait; then
	    echo >&2 " - MySQL restricted mode process failed."
	    exit 4
	fi
    fi

    chown -R mysql:mysql "$DATADIR"

    echo
    echo "Ready for start up in production mode."
    echo

fi

exec "$@"
