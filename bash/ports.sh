#!/bin/bash

PORT_RANGE_MIN=9000
PORT_RANGE_MAX=9005
BIND_PORT_TIMEOUT=10
DEBUG=false

function _isPortAvailable () {
  local port=$1
  local lsof=$(which lsof 2>&1)
  [ ! -x "$lsof" ] && echo "Error: Missing lsof utility: Couldn't check for port availability." && exit 127
  $DEBUG && echo "Checking for port ${port} availability..."
  $lsof -n -P -i ":${port}" | grep -q LISTEN
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
    [ "$BIND_PORT_TIMEOUT" -le "$elapsed_time" ] && echo "Timeout: Couldn't bind port ${port} after ${BIND_PORT_TIMEOUT} seconds." && return 1
    echo "Done." && return 0
  fi
  echo "Error: Couldn't launch WebServer." && return 1
}

function _launchWebServer () {
  local name=$1
  for port in $(seq "$PORT_RANGE_MIN" "$PORT_RANGE_MAX"); do
    _isPortAvailable "$port" || continue
    echo "Found available port: ${port}." && _createWebServer "$name" "$port" && return 0 || return 1
  done
  echo "Error: Couldn't find available ports within the specified range [${PORT_RANGE_MIN}..${PORT_RANGE_MAX}]" && return 1
}

#######################################################################################################################################################

for ws in {1..10} ; do
  _launchWebServer "$ws"
done
