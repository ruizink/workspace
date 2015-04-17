#!/bin/bash

PORT_RANGE_MIN=9000
PORT_RANGE_MAX=9049
PORT_RANGE_LWM=0      # port range low water mark
BIND_PORT_TIMEOUT=10
DEBUG=false

function _isPortAvailable () {
  local port=$1
  $DEBUG && echo "Checking for port ${port} availability..."
  /usr/sbin/lsof -i -n -P | grep LISTEN | grep -q ":${port}"
  if [ $? -ne 0 ]; then
    $DEBUG && echo "Port ${port} is available."
    return 0
  fi
  $DEBUG && echo "Port ${port} is in use!"
  return 1
}

function _createWebServer () {
  local name=$1
  local port=$2
  local elapsed_time=0
  echo "Launching WebServer '${name}' on port ${port}..."
  python -m SimpleHTTPServer "$port" &
  if [ $? -eq 0 ]; then
    $DEBUG && echo "Waiting for port binding..."
    while _isPortAvailable "$port" && [ "$BIND_PORT_TIMEOUT" -gt "$elapsed_time" ]; do
      $DEBUG && echo "${elapsed_time}s: Port not bound yet..."
      sleep 1 && ((elapsed_time++))
    done
    [ "$BIND_PORT_TIMEOUT" -le "$elapsed_time" ] && echo "Timeout: Couldn't bind port ${port} after ${BIND_PORT_TIMEOUT} seconds!" && return 1
    echo "Done." && return 0
  fi
  return 1
}

function _launchWebServer () {
  [ $PORT_RANGE_LWM -lt $PORT_RANGE_MIN ] && PORT_RANGE_LWM=$PORT_RANGE_MIN
  for port in $(seq "$PORT_RANGE_LWM" "$PORT_RANGE_MAX"); do
    _isPortAvailable "$port" && echo "Found available port: ${port}." && _createWebServer "$1" "$port" && return 0
    ((PORT_RANGE_LWM++))
  done
  echo "Error: Couldn't find available ports within the specified range [${PORT_RANGE_MIN}..${PORT_RANGE_MAX}] !" && return 1
}

#######################################################################################################################################################

for ws in {1..100}; do
  _launchWebServer "$ws"
done
