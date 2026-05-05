FROM nixos/nix:latest

# Enable flakes and the daemon mode for builders
RUN mkdir -p /etc/nix && \
    echo 'experimental-features = nix-command flakes' > /etc/nix/nix.conf && \
    echo ' builders = @/etc/nix/builders' >> /etc/nix/nix.conf && \
    echo 'sandbox = false' >> /etc/nix/nix.conf

# Install basic tools for testing
RUN nix --version
RUN ls /etc/nix/nix.conf

# Copy the installer into the container
COPY . /opt/reticulum-installer

CMD ["/bin/bash"]