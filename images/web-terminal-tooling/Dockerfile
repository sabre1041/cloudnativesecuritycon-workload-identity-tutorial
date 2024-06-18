FROM registry.redhat.io/web-terminal/web-terminal-tooling-rhel8:1.10

ARG VAULT_VERSION=1.17.0

USER 0

# Install packages
RUN microdnf update -y && \
    microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y gettext unzip && \
    microdnf clean all

# Install Vault
RUN mkdir vault-install && \
    curl -o vault-install/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
    unzip -d vault-install vault-install/vault.zip && \
    mv vault-install/vault /usr/local/bin/ && \
    rm -rf vault-install

USER 1001

