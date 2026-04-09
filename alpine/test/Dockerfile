FROM alpine:3.21

# Install OpenRC and basic tools
RUN apk add --no-cache openrc bash procps

# Needed to run OpenRC inside a container
RUN mkdir -p /run/openrc && touch /run/openrc/softlevel

# Copy the installer into the container
COPY . /opt/reticulum-installer

CMD ["/bin/bash"]
