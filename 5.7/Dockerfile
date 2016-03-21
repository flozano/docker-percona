# vim:set ft=dockerfile:
FROM aggr/ubuntu

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

# install "pwgen" for randomizing passwords
RUN apt-get update && apt-get install -y pwgen && rm -rf /var/lib/apt/lists/*

RUN mkdir /docker-entrypoint-initdb.d

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 430BDF5C56E7C94E848EE60C1C4CBDCDCD2EFD2A

RUN echo 'deb http://repo.percona.com/apt trusty main' > /etc/apt/sources.list.d/percona.list

ENV PERCONA_MAJOR 5.7
ENV PERCONA_VERSION 5.7.11-4-1.trusty

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
	echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password password 'unused'; \
	echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password_again password 'unused'; \
    } | debconf-set-selections \
    && apt-get -qq update \
    && apt-get install -qqy percona-server-server-$PERCONA_MAJOR=$PERCONA_VERSION \
    && rm -rf /etc/mysql/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

ADD https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip /tmp/
RUN unzip -qq /tmp/consul-template_0.14.0_linux_amd64.zip -d /usr/bin
ADD percona-master.ctmpl /tmp/percona-master.ctmpl	
	
VOLUME ["/var/lib/mysql", "/var/log/mysql", "/etc/mysql"]

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
