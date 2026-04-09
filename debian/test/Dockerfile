FROM debian:bookworm

# systemd needs these to run inside a container
ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

# Install systemd and clean up unnecessary units
RUN apt-get update -qq && \
    apt-get install -y -qq systemd systemd-sysv dbus procps && \
    apt-get clean && \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
          /etc/systemd/system/*.wants/* \
          /lib/systemd/system/local-fs.target.wants/* \
          /lib/systemd/system/sockets.target.wants/*udev* \
          /lib/systemd/system/sockets.target.wants/*initctl* \
          /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
          /lib/systemd/system/systemd-update-utmp*

# Copy the installer into the container
COPY . /opt/reticulum-installer

VOLUME [ "/sys/fs/cgroup" ]
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
