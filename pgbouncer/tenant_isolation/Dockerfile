FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and pgbouncer
RUN apt-get update && apt-get install -y \
	gnupg \
	wget \
	lsb-release \
    systemd \
    systemd-sysv \
    procps \
    net-tools \
	&& wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
	&& echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
	&& apt-get update && apt-get install -y pgbouncer postgresql-client \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Clean systemd (standard docker-systemd boilerplate)
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
    ls | grep -v systemd-tmpfiles-setup | xargs rm -f && \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*

# directories
RUN mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer /tmp && \
	chown -R postgres:postgres /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer

# Copy configs
COPY config/pgbouncer@.service /etc/systemd/system/
COPY config/pgbouncer_tenant_a.ini /etc/pgbouncer/
COPY config/userlist_tenant_a.txt /etc/pgbouncer/
COPY config/pgbouncer_tenant_b.ini /etc/pgbouncer/
COPY config/userlist_tenant_b.txt /etc/pgbouncer/

# Perms
RUN chown -R postgres:postgres /etc/pgbouncer

# Enable services
RUN systemctl enable pgbouncer@tenant_a.service && \
    systemctl enable pgbouncer@tenant_b.service

EXPOSE 6432 6433

CMD ["/lib/systemd/systemd"]
