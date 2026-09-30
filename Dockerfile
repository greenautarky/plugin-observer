ARG BUILD_FROM

# Built with a current, maintained Go release. Digest-pinned; GOTOOLCHAIN=local
# so go.mod cannot switch the build to a different toolchain.
FROM --platform=amd64 golang:1.26.8-alpine@sha256:8ac98ca534ac3f51e1f420a1dd2c15e74c75cfa0f23f3ad27eb5d7236c349a0c AS builder

WORKDIR /workspace/observer-plugin
ARG BUILD_ARCH
ENV GOTOOLCHAIN=local

COPY . .

# Build
RUN \
        if [ "${BUILD_ARCH}" = "armhf" ]; then \
            CGO_ENABLED=0 GOARM=6 GOARCH=arm go build -ldflags="-s -w"; \
        elif [ "${BUILD_ARCH}" = "armv7" ]; then \
            CGO_ENABLED=0 GOARM=7 GOARCH=arm go build -ldflags="-s -w"; \
        elif [ "${BUILD_ARCH}" = "aarch64" ]; then \
            CGO_ENABLED=0 GOARCH=arm64 go build -ldflags="-s -w"; \
        elif [ "${BUILD_ARCH}" = "i386" ]; then \
            CGO_ENABLED=0 GOARCH=386 go build -ldflags="-s -w"; \
        elif [ "${BUILD_ARCH}" = "amd64" ]; then \
            CGO_ENABLED=0 GOARCH=amd64 go build -ldflags="-s -w"; \
        else \
            exit 1; \
        fi \
    && cp -f plugin-observer /workspace/observer \
    && rm -rf /workspace/observer-plugin


FROM ${BUILD_FROM}

ENV DOCKER_HOST="unix:///run/docker.sock"

WORKDIR /
COPY --from=builder /workspace/observer /usr/bin/observer
COPY rootfs /

ENTRYPOINT ["/usr/bin/observer"]
