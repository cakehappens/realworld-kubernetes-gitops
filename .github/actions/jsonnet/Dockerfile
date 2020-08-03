FROM golang:buster as golang-binaries

RUN set -ex; \
    go get github.com/google/go-jsonnet/cmd/jsonnet; \
    jsonnet --version;

RUN set -ex; \
    go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb; \
    jb --version;

FROM debian:buster-slim

RUN set -ex; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      jq \
      make \
      bash \
      git \
      gawk \
      curl \
      ; \
    apt-get autoclean; \
    rm -rf /var/lib/apt-lists/*;

SHELL [ "/bin/bash", "-Eexuo", "pipefail", "-c" ]

# YQ
RUN YQ_URL="https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64"; \
    curl --silent --show-error --location --fail --retry 3 --output /usr/local/bin/yq $YQ_URL; \
    chmod +x /usr/local/bin/yq; \
    yq --version;

COPY --from=golang-binaries /go/bin /usr/bin

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
