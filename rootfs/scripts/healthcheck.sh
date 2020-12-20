#!/usr/bin/env bash
set -e

EXITCODE=0

if [ -f "/run/readsb/aircraft.json" ]; then

    # get latest timestamp of readsb json update
    TIMESTAMP_LAST_READSB_UPDATE=$(jq '.now' < /run/readsb/aircraft.json)

    # get current timestamp
    TIMESTAMP_NOW=$(date +"%s.%N")

    # makse sure readsb has updated json in past 60 seconds
    TIMEDELTA=$(echo "$TIMESTAMP_NOW - $TIMESTAMP_LAST_READSB_UPDATE" | bc)
    if [ "$(echo "$TIMEDELTA" \< 60 | bc)" -ne 1 ]; then
        echo "readsb last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. UNHEALTHY"
        EXITCODE=1
    else
        echo "readsb last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. HEALTHY"
    fi

    # get number of aircraft
    NUM_AIRCRAFT=$(jq '.aircraft | length' < /run/readsb/aircraft.json)
    if [ "$NUM_AIRCRAFT" -lt 1 ]; then
        echo "total aircraft: $NUM_AIRCRAFT. UNHEALTHY"
        EXITCODE=1
    else
        echo "total aircraft: $NUM_AIRCRAFT. HEALTHY"
    fi

else

    echo "WARNING: Cannot find /run/readsb/aircraft.json, so skipping some checks."

fi

# originally was going to check to make sure ports open, however the user
# could deliberately close ports, so will leave this out.

# # check port 30001 is open
# if [ $(netstat -an | grep LISTEN | grep ":30001" | wc -l) -ge 1 ]; then
#     echo "TCP port 30001 open. HEALTHY"
# else
#     echo "TCP port 30001 not open. UNHEALTHY"
#     EXITCODE=1
# fi

# # check port 30002 is open
# if [ $(netstat -an | grep LISTEN | grep ":30002" | wc -l) -ge 1 ]; then
#     echo "TCP port 30002 open. HEALTHY"
# else
#     echo "TCP port 30002 not open. UNHEALTHY"
#     EXITCODE=1
# fi

# # check port 30003 is open
# if [ $(netstat -an | grep LISTEN | grep ":30003" | wc -l) -ge 1 ]; then
#     echo "TCP port 30003 open. HEALTHY"
# else
#     echo "TCP port 30003 not open. UNHEALTHY"
#     EXITCODE=1
# fi

# # check port 30004 is open
# if [ $(netstat -an | grep LISTEN | grep ":30004" | wc -l) -ge 1 ]; then
#     echo "TCP port 30004 open. HEALTHY"
# else
#     echo "TCP port 30004 not open. UNHEALTHY"
#     EXITCODE=1
# fi

# # check port 30005 is open
# if [ $(netstat -an | grep LISTEN | grep ":30005" | wc -l) -ge 1 ]; then
#     echo "TCP port 30005 open. HEALTHY"
# else
#     echo "TCP port 30005 not open. UNHEALTHY"
#     EXITCODE=1
# fi

# death count for lighttpd
#shellcheck disable=SC2126
LIGHTTPD_DEATHS=$(s6-svdt /run/s6/services/lighttpd | grep -v "exitcode 0" | wc -l)
if [ "$LIGHTTPD_DEATHS" -ge 1 ]; then
    echo "lighttpd deaths: $LIGHTTPD_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "lighttpd deaths: $LIGHTTPD_DEATHS. HEALTHY"
fi
s6-svdt-clear /run/s6/services/lighttpd

# death count for mlat_hub
#shellcheck disable=SC2126
MLATHUB_DEATHS=$(s6-svdt /run/s6/services/mlat_hub | grep -v "exitcode 0" | wc -l)
if [ "$MLATHUB_DEATHS" -ge 1 ]; then
    echo "mlat_hub deaths: $MLATHUB_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "mlat_hub deaths: $MLATHUB_DEATHS. HEALTHY"
fi
s6-svdt-clear /run/s6/services/mlat_hub

exit $EXITCODE
