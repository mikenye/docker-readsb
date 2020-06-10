#!/usr/bin/env bash
set -e

EXITCODE=0

if [ -f "/run/readsb/aircraft.json" ]; then

    # get latest timestamp of readsb json update
    TIMESTAMP_LAST_READSB_UPDATE=$(cat /run/readsb/aircraft.json | jq '.now')

    # get current timestamp
    TIMESTAMP_NOW=$(date +"%s.%N")

    # makse sure readsb has updated json in past 60 seconds
    TIMEDELTA=$(echo "$TIMESTAMP_NOW - $TIMESTAMP_LAST_READSB_UPDATE" | bc)
    if [ $(echo $TIMEDELTA \< 60 | bc) -ne 1 ]; then
        echo "readsb last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. UNHEALTHY"
        EXITCODE=1
    else
        echo "readsb last updated: ${TIMESTAMP_LAST_READSB_UPDATE}, now: ${TIMESTAMP_NOW}, delta: ${TIMEDELTA}. HEALTHY"
    fi

    # get number of aircraft
    NUM_AIRCRAFT=$(cat /run/readsb/aircraft.json | jq '.aircraft | length')
    if [ $NUM_AIRCRAFT -lt 1 ]; then
        echo "total aircraft: $NUM_AIRCRAFT. UNHEALTHY"
        EXITCODE=1
    else
        echo "total aircraft: $NUM_AIRCRAFT. HEALTHY"
    fi

else

    echo "WARNING: Cannot find /run/readsb/aircraft.json, so skipping some checks."

fi

# death count for lighttpd
LIGHTTPD_DEATHS=$(s6-svdt /run/s6/services/lighttpd | grep -v "exitcode 0" | wc -l)
if [ $LIGHTTPD_DEATHS -ge 1 ]; then
    echo "lighttpd deaths: $LIGHTTPD_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "lighttpd deaths: $LIGHTTPD_DEATHS. HEALTHY"
fi
s6-svdt-clear /run/s6/services/lighttpd

# death count for mlat_hub
MLATHUB_DEATHS=$(s6-svdt /run/s6/services/mlat_hub | grep -v "exitcode 0" | wc -l)
if [ $MLATHUB_DEATHS -ge 1 ]; then
    echo "mlat_hub deaths: $MLATHUB_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "mlat_hub deaths: $MLATHUB_DEATHS. HEALTHY"
fi
s6-svdt-clear /run/s6/services/mlat_hub

exit $EXITCODE
