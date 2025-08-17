#!/usr/bin/with-contenv bashio
set -euo pipefail

NAME="$(bashio::config 'name')"
OUTPUT_DEVICE="$(bashio::config 'output_device')"
MIXER_CONTROL="$(bashio::config 'mixer_control')"
VOLUME_DB="$(bashio::config 'volume_db')"
INTERPOLATION="$(bashio::config 'interpolation')"
DRIFT="$(bashio::config 'drift_tolerance')"
AIRPLAY2="$(bashio::config 'enable_airplay2')"
EXTRA_ARGS="$(bashio::config 'extra_args')"

bashio::log.info "Configuring Shairport Sync (name: ${NAME}, device: ${OUTPUT_DEVICE}, AirPlay 2: ${AIRPLAY2})"

# Create shairport-sync config
cat >/etc/shairport-sync.conf <<EOF
general =
{
  name = "${NAME}";
  interpolation = "${INTERPOLATION}";
  drift_tolerance_in_seconds = ${DRIFT};
  output_backend = "alsa";
  mdns_backend = "tinysvcmdns";
  volume_max_db = ${VOLUME_DB};
  # diagnostics = { log_verbosity = 0; };
};

alsa =
{
  output_device = "${OUTPUT_DEVICE}";
  $( [ -n "${MIXER_CONTROL}" ] && echo "mixer_control_name = \"${MIXER_CONTROL}\";" )
};
EOF

# If AirPlay 2 enabled, start nqptp first (it will daemonize/foreground depending on build)
if [ "${AIRPLAY2}" = "true" ]; then
  bashio::log.info "Starting NQPTP for AirPlay 2 timing..."
  # Run nqptp in background; shairport-sync will detect it automatically
  (nqptp -v 2>&1 | sed 's/^/[nqptp] /') &
  sleep 1
fi

# Show ALSA devices for troubleshooting
bashio::log.info "ALSA devices detected:"
aplay -l || true
aplay -L || true

# Exec shairport-sync in foreground (s6 will supervise)
bashio::log.info "Starting Shairport Sync..."
exec shairport-sync -c /etc/shairport-sync.conf -vv ${EXTRA_ARGS}
