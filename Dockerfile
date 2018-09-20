FROM centos:7

LABEL name="crunchydata/postgres" \
	vendor="crunchy data" \
	PostgresVersion="9.6" \
	PostgresFullVersion="9.6.10" \
	Version="7.5" \
	Release="2.1.0" \
        url="https://crunchydata.com" \
	summary="PostgreSQL 9.6.10 (PGDG) on a Centos7 base image" \
        description="Allows multiple deployment methods for PostgreSQL, including basic single primary, streaming replication with synchronous and asynchronous replicas, and stateful sets. Includes utilities for Auditing (pgaudit), statement tracking, and Backup / Restore (pgbackrest, pg_basebackup)." \
        io.k8s.description="postgres container" \
        io.k8s.display-name="Crunchy postgres container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

ENV PGVERSION="9.6" PGDG_REPO="pgdg-centos96-9.6-3.noarch.rpm"

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/${PGVERSION}/redhat/rhel-7-x86_64/${PGDG_REPO}

RUN yum -y update && yum -y install epel-release \
 && yum -y update glibc-common \
 && yum -y install bind-utils \
    gettext \
    hostname \
    nss_wrapper \
    openssh-server \
    kubernetes-client \
    procps-ng  \
    rsync \
 && yum -y install postgresql96-server postgresql96-contrib postgresql96 \
    pgaudit_96 \
    pgbackrest \
 && yum -y clean all

ENV PGROOT="/usr/pgsql-${PGVERSION}"

# add path settings for postgres user
# bash_profile is loaded in login, but not with exec
# bashrc to set permissions in OCP when using exec
# HOME is / in OCP
ADD conf/.bash_profile /var/lib/pgsql/
ADD conf/.bash_profile /
# ADD conf/.bashrc /

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /pgwal /pgconf /backup /recover /backrestrepo /sshd

RUN chown -R postgres:postgres /opt/cpm /var/lib/pgsql \
    /pgdata /pgwal /pgconf /backup /recover /backrestrepo
    
RUN chmod -R 777 /opt/cpm /var/lib/pgsql \
    /pgdata /pgwal /pgconf /backup /recover /backrestrepo    

# Link pgbackrest.conf to default location for convenience
RUN ln -sf /tmp/pgbackrest.conf /etc/pgbackrest.conf

# add volumes to allow override of pg_hba.conf and postgresql.conf
# add volumes to allow backup of postgres files
# add volumes to offer a restore feature
# add volumes to allow storage of postgres WAL segment files
# add volumes to locate WAL files to recover with
# add volumes for pgbackrest to write to
# add volumes for sshd host keys

VOLUME ["/pgconf", "/pgdata", "/pgwal", "/backup", "/recover", "/backrestrepo", "/sshd"]

# open up the postgres port
EXPOSE 5432

ADD bin/postgres /opt/cpm/bin
# ADD bin/common /opt/cpm/bin
ADD conf/postgres /opt/cpm/conf
# ADD tools/pgmonitor/exporter/postgres /opt/cpm/bin/pgmonitor

USER 26

CMD ["/opt/cpm/bin/start.sh"]
