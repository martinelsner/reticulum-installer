FROM debian:bookworm

# systemd needs these to run inside a container
ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

# Install systemd, Python and basic tools
RUN apt-get update -qq && \
    apt-get install -y -qq systemd systemd-sysv dbus procps python3 python3-pip python3-venv && \
    apt-get clean && \
    rm -f /lib/systemd/system/multi-user.target.wants/* \
          /etc/systemd/system/*.wants/* \
          /lib/systemd/system/local-fs.target.wants/* \
          /lib/systemd/system/sockets.target.wants/*udev* \
          /lib/systemd/system/sockets.target.wants/*initctl* \
          /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
          /lib/systemd/system/systemd-update-utmp*

# Disable AppArmor for containers
RUN apt-get update -qq && apt-get install -y -qq apparmor && ln -sf /etc/apparmor.d/disable /etc/apparmor.d/disable/apparmor-containerized || true

# Copy the installer into the container
COPY . /opt/reticulum-installer

VOLUME [ "/sys/fs/cgroup" ]
STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
