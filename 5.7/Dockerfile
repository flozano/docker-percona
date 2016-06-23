# vim:set ft=dockerfile:
FROM aggr/ubuntu

ENV PERCONA_MAJOR 5.7
ENV PERCONA_VERSION 5.7.12-5-1.trusty

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

# install "pwgen" for randomizing passwords
RUN apt-get -qq update && apt-get install -qqy pwgen && rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A
RUN echo 'deb http://repo.percona.com/apt trusty main' > /etc/apt/sources.list.d/percona.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
	echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password password 'unused'; \
	echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password_again password 'unused'; \
    } | debconf-set-selections \
    && apt-get -qq update && DEBIAN_FRONTEND=noninteractive \
    && apt-get install -qqy percona-server-server-$PERCONA_MAJOR=$PERCONA_VERSION \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

RUN mkdir /docker-entrypoint-initdb.d
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME ["/var/lib/mysql", "/var/log/mysql", "/etc/mysql"]

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
