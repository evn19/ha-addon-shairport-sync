# Let the HA builder pick the right per-arch base
ARG BUILD_FROM
FROM $BUILD_FROM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG=C.UTF-8

# Build-time versions (you can pin these)
ENV SHAIRPORT_SYNC_REPO="https://github.com/mikebrady/shairport-sync.git"
ENV SHAIRPORT_SYNC_REF="master"
ENV NQPTP_REPO="https://github.com/mikebrady/nqptp.git"
ENV NQPTP_REF="master"

# Runtime deps first, then build deps
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      alsa-utils \
      libasound2 \
      libsoxr0 \
      libmbedtls12 \
      libpopt0 \
      libconfig9 \
      avahi-utils \
      curl \
      tzdata \
 && rm -rf /var/lib/apt/lists/*

# Build Shairport Sync (with ALSA + tinysvcmdns + mbedTLS + soxr + metadata)
# Also build NQPTP, used for AirPlay 2 timing (we can start it conditionally).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential git autoconf automake libtool pkg-config \
      libasound2-dev libsoxr-dev libmbedtls-dev libpopt-dev libconfig-dev \
 && git clone --depth=1 --branch "${SHAIRPORT_SYNC_REF}" "${SHAIRPORT_SYNC_REPO}" /tmp/shairport-sync \
 && cd /tmp/shairport-sync \
 && autoreconf -fi \
 && ./configure \
      --sysconfdir=/etc \
      --with-alsa \
      --with-tinysvcmdns \
      --with-metadata \
      --with-ssl=mbedtls \
      --with-soxr \
      --with-systemd \
 && make -j"$(nproc)" \
 && make install \
 && ldconfig \
 && git clone --depth=1 --branch "${NQPTP_REF}" "${NQPTP_REPO}" /tmp/nqptp \
 && cd /tmp/nqptp \
 && autoreconf -fi \
 && ./configure \
 && make -j"$(nproc)" \
 && make install \
 && ldconfig \
 && apt-get purge -y build-essential git autoconf automake libtool pkg-config \
                    libasound2-dev libsoxr-dev libmbedtls-dev libpopt-dev libconfig-dev \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/* /tmp/*

# S6 services and runtime
COPY rootfs/ /
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh /etc/services.d/shairport/run /etc/services.d/shairport/finish

# Home Assistant audio expects this
ENV S6_SERVICES_GRACETIME=5000
s