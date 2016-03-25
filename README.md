# docker-percona
Percona MySQL Database


[![Travis CI](https://img.shields.io/travis/rusxakep/docker-percona/master.svg)](https://travis-ci.org/rusxakep/docker-percona/branches)

# Usage:

### 1. MySQL master node (minimal):
````
root@docker:~# docker run --restart=unless-stopped \
--name percona-master \
-e MYSQL_MYSQLD_BIND_ADDRESS=0.0.0.0 \
-e MYSQL_MYSQLD_SERVER_ID=1 \
-e MYSQL_MYSQLD_GTID_MODE=ON \
-e MYSQL_MYSQLD_ENFORCE_GTID_CONSISTENCY=true \
-e MYSQL_MYSQLD_LOG_BIN=/var/lib/mysql/binary-log \
-e MYSQL_MYSQLD_BINLOG_IGNORE_DB="mysql" \
-e MYSQL_MYSQLD_BINLOG_FORMAT=ROW \
-e MYSQL_MYSQLD_LOG_SLAVE_UPDATES=true \
-e MYSQL_ROOT_PASSWORD="root-password" \
-e REPLICATION_MASTER=true \
-e REPLICATION_USER=replica \
-e REPLICATION_PASS=replica \
-p 3306:3306 \
-d aggr/percona
````

### 2. MySQL slave node 01 (minimal):
````
root@docker:~# docker run --restart=unless-stopped \
--name percona-slave01 \
-e MYSQL_MYSQLD_BIND_ADDRESS=0.0.0.0 \
-e MYSQL_MYSQLD_SERVER_ID=2 \
-e MYSQL_MYSQLD_LOG_BIN=/var/lib/mysql/replication/binary-log \
-e MYSQL_MYSQLD_GTID_MODE=ON \
-e MYSQL_MYSQLD_ENFORCE_GTID_CONSISTENCY=true \
-e MYSQL_MYSQLD_LOG_SLAVE_UPDATES=true \
-e MYSQL_ROOT_PASSWORD="other-root-password" \
-e REPLICATION_SLAVE=true \
-e MYSQL_MASTER_ADDR=mysql-master \
-e MYSQL_MASTER_PORT=3306 \
-e REPLICATION_USER=replica \
-e REPLICATION_PASS=replica \
-p 3307:3306 \
-l mysql-master:percona-master
-d aggr/percona
````

### 3. MySQL slave node 02 (minimal):
````
root@docker:~# docker run --restart=unless-stopped \
--name percona-slave02 \
-e MYSQL_MYSQLD_BIND_ADDRESS=0.0.0.0 \
-e MYSQL_MYSQLD_SERVER_ID=3 \
-e MYSQL_MYSQLD_LOG_BIN=/var/lib/mysql/replication/binary-log \
-e MYSQL_MYSQLD_GTID_MODE=ON \
-e MYSQL_MYSQLD_ENFORCE_GTID_CONSISTENCY=true \
-e MYSQL_MYSQLD_LOG_SLAVE_UPDATES=true \
-e MYSQL_ROOT_PASSWORD="next-other-root-password" \
-e REPLICATION_SLAVE=true \
-e MYSQL_MASTER_ADDR=mysql-master \
-e MYSQL_MASTER_PORT=3306 \
-e REPLICATION_USER=replica \
-e REPLICATION_PASS=replica \
-p 3308:3306 \
-l mysql-master:percona-master
-d aggr/percona
````

.... more and more slave node's ....

### 4. MySQL master (single) node (no slave):
````
root@docker:~# docker run --restart=unless-stopped \
--name percona \
-e MYSQL_MYSQLD_BIND_ADDRESS=0.0.0.0 \
-e MYSQL_ROOT_PASSWORD="root-password" \
-p 3306:3306 \
-d aggr/percona
````

### 5. If you want add persistent storage for database files:
````
root@docker:~# docker run --restart=unless-stopped \
--name percona \
-v /mnt/volumes/percona:/var/lib/mysql \
-e MYSQL_MYSQLD_BIND_ADDRESS=0.0.0.0 \
-p 3306:3306 \
-d aggr/percona
````

### 6. If you want an easier start than before, add persistent storage for config:
````
root@docker:~# docker run --restart=unless-stopped \
--name percona \
-v /mnt/config/percona:/etc/mysql \
-v /mnt/volumes/percona:/var/lib/mysql \
-e MYSQL_MYSQLD_BIND_ADDRESS=0.0.0.0 \
-p 3306:3306 \
-d aggr/percona
````

### 7. MySQL master node (complex example):
````
root@docker:~# docker run --restart=unless-stopped \
--name percona-master \
-e MYSQL_MYSQLD_BIND_ADDRESS=0.0.0.0 \
-e MYSQL_MYSQLD_SERVER_ID=1 \
-e MYSQL_MYSQLD_DATADIR=/var/lib/mysql/db \
-e MYSQL_MYSQLD_INNODB_DATA_HOME_DIR=/var/lib/mysql/innodb \
-e MYSQL_MYSQLD_INNODB_LOG_GROUP_HOME_DIR=/var/lib/mysql/innodb \
-e MYSQL_MYSQLD_LOG_BIN=/var/lib/mysql/replication/binary-log \
-e MYSQL_MYSQLD_MASTER_INFO_FILE=/var/lib/mysql/replication/master.info \
-e MYSQL_MYSQLD_RELAY_LOG=/var/lib/mysql/replication/relay-log \
-e MYSQL_MYSQLD_RELAY_LOG_INFO_FILE=/var/lib/mysql/replication/relay-log.info \
-e MYSQL_MYSQLD_RELAY_LOG_INDEX=/var/lib/mysql/replication/relay-log.index \
-e MYSQL_MYSQLD_SLOW_QUERY_LOG=ON \
-e MYSQL_MYSQLD_EXPIRE_LOG_DAYS=7 \
-e MYSQL_MYSQLD_BINLOG_CHECKSUM=crc32 \
-e MYSQL_MYSQLD_GTID_MODE=ON \
-e MYSQL_MYSQLD_ENFORCE_GTID_CONSISTENCY=true \
-e MYSQL_MYSQLD_SYNC_BINLOG=100 \
-e MYSQL_MYSQLD_BINLOG_IGNORE_DB="mysql" \
-e MYSQL_MYSQLD_BINLOG_ROW_EVENT_MAX_SIZE=8192 \
-e MYSQL_MYSQLD_BINLOG_FORMAT=ROW \
-e MYSQL_MYSQLD_LARGE_PAGES=true \
-e MYSQL_MYSQLD_SKIP_NAME_RESOLVE=true \
-e MYSQL_MYSQLD_SKIP_HOST_CACHE=true \
-e MYSQL_MYSQLD_SKIP_EXTERNAL_LOCKING=true \
-e MYSQL_MYSQLD_SKIP_INNODB_DOUBLEWRITE=true \
-e MYSQL_MYSQLD_SYMBOLIC_LINKS=0 \
-e MYSQL_MYSQLD_EVENT_SCHEDULER=ON \
-e MYSQL_MYSQLD_DEFAULT_STORAGE_ENGINE=InnoDB \
-e MYSQL_MYSQLD_CHARACTER_SET_SERVER=utf8 \
-e MYSQL_MYSQLD_COLLATION_SERVER=utf8_bin \
-e MYSQL_MYSQLD_INIT_CONNECT="SET NAMES utf8 collate utf8_bin" \
-e MYSQL_MYSQLD_LOG_SLAVE_UPDATES=true \
-e MYSQL_MYSQLD_CONNECT_TIMEOUT=600000 \
-e MYSQL_MYSQLD_WAIT_TIMEOUT=28800 \
-e MYSQL_MYSQLD_MAX_CONNECTIONS=1000 \
-e MYSQL_MYSQLD_MAX_ALLOWED_PACKET=32M \
-e MYSQL_MYSQLD_MAX_CONNECT_ERRORS=10000 \
-e MYSQL_MYSQLD_NET_READ_TIMEOUT=600000 \
-e MYSQL_MYSQLD_NET_WRITE_TIMEOUT=600000 \
-e MYSQL_MYSQLD_LOG_QUERIES_NOT_USING_INDEXES=1 \
-e MYSQL_MYSQLD_TRANSACTION_ISOLATION=READ-COMMITTED \
-e MYSQL_MYSQLD_LC_MESSAGES_DIR=/usr/share/mysql \
-e MYSQL_MYSQLD_INNODB_FILE_PER_TABLE=1 \
-e MYSQL_MYSQLD_INNODB_OPEN_FILES=256 \
-e MYSQL_MYSQLD_INNODB_BUFFER_POOL_SIZE=128M \
-e MYSQL_MYSQLD_INNODB_BUFFER_POOL_INSTANCES=2 \
-e MYSQL_MYSQLD_INNODB_FLUSH_LOG_AT_TRX_COMMIT=2 \
-e MYSQL_MYSQLD_INNODB_FLUSH_METHOD=O_DIRECT \
-e MYSQL_MYSQLD_INNODB_LOG_BUFFER_SIZE=8M \
-e MYSQL_MYSQLD_INNODB_AUTOEXTEND_INCREMENT=256 \
-e MYSQL_MYSQLD_INNODB_CONCURRENCY_TICKETS=1000 \
-e MYSQL_MYSQLD_INNODB_DATA_FILE_PATH=ibdata1:100M:autoextend \
-e MYSQL_MYSQLD_INNODB_LOG_FILES_IN_GROUP=2 \
-e MYSQL_MYSQLD_INNODB_OLD_BLOCKS_TIME=1000 \
-e MYSQL_MYSQLD_INNODB_STATS_ON_METADATA=OFF \
-e MYSQL_MYSQLD_INNODB_FAST_SHUTDOWN=0 \
-e MYSQL_MYSQLD_INNODB_LOG_FILE_SIZE=32M \
-e MYSQL_MYSQLD_EXPLICIT_DEFAULTS_FOR_TIMESTAMP=1 \
-e MYSQL_MYSQLD_PERFORMANCE_SCHEMA=ON \
-e MYSQL_MYSQLD_QUERY_CACHE_SIZE=0 \
-e MYSQL_MYSQLD_QUERY_CACHE_TYPE=0 \
-e MYSQL_MYSQLD_QUERY_CACHE_MIN_RES_UNIT=0 \
-e MYSQL_MYSQLD_JOIN_BUFFER_SIZE=8M \
-e MYSQL_MYSQLD_READ_RND_BUFFER_SIZE=3M \
-e MYSQL_MYSQLD_TABLE_DEFINITION_CACHE=1024 \
-e MYSQL_MYSQLD_TABLE_OPEN_CACHE=4096 \
-e MYSQL_MYSQLD_THREAD_CACHE_SIZE=256 \
-e MYSQL_MYSQLD_TMP_TABLE_CACHE=32M \
-e MYSQL_MYSQLD_MAX_HEAP_TABLE_SIZE=32M \
-e MYSQL_MYSQLD_THREAD_HANDLING=pool-of-threads \
-e MYSQL_MYSQLD_THREAD_POOL_SIZE=1 \
-e MYSQL_ROOT_PASSWORD="root-password" \
-e MYSQL_USER=example_user \
-e MYSQL_PASSWORD="user-password" \
-e MYSQL_DATABASE=example \
-e REPLICATION_MASTER=true \
-e REPLICATION_USER=replica \
-e REPLICATION_PASS=replica \
-p 3306:3306 \
-d aggr/percona
````

### Additional some useful options:
````
MYSQL_ONETIME_PASSWORD - expire root password after start container
MYSQL_RANDOM_ROOT_PASSWORD - generating absolutly random password for root (see logs)
MYSQL_INITDB_SKIP_TZINFO - if you using STRICT_ALL_TABLES (https://bugs.mysql.com/bug.php?id=20545)
````

### Please use logger for check any configuration errors:
````
root@docker:~# docker logs -f percona

Creating /etc/mysql/conf.d/mysqld.cnf from environment parameters ...
 - checking and writing user = mysql
 - checking and writing datadir = /var/lib/mysql/db
 - checking and writing bind-address = 0.0.0.0
 - checking and writing server-id = 1
 .....
 .....
 - checking and writing max_heap_table_size = 32M
 - checking and writing thread_handling = pool-of-threads
 - checking and writing thread_pool_size = 1

 Ready for start up in production mode.
 ````