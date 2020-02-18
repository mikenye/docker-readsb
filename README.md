# mikenye/readsb
[Mictronics' `readsb`](https://github.com/Mictronics/readsb) Mode-S/ADSB/TIS decoder for RTLSDR, BladeRF, Modes-Beast and GNS5894 devices, running in a docker container. 

Support for RTLSDR, bladeRF and plutoSDR is compiled in. Builds and runs on x86_64, arm32v7 and arm64v8 (see below).

This image will configure a software-defined radio (SDR) to receive and decode Mode-S/ADSB/TIS data from aircraft within range, for use with other services such as:
 * `mikenye/adsbexchange` to feed ADSB data to [adsbexchange.com](https://adsbexchange.com)
 * `mikenye/piaware` to feed ADSB data into [flightaware.com](https://flightaware.com)
 * `mikenye/fr24feed` to feed ADSB data into [flightradar24.com](https://www.flightradar24.com)
 * `mikenye/piaware-to-influx` to feed data into your own instance of [InfluxDB](https://docs.influxdata.com/influxdb/), for visualisation with [Grafana](https://grafana.com) and/or other tools
 * Any other tools that can receive Beast, BeastReduce, Basestation or the raw data feed from `readsb` or `dump1090` and their variants

Tested and working on:
 * `x86_64` (`amd64`) platform running Ubuntu 16.04.4 LTS using an RTL2832U radio (FlightAware Pro Stick Plus Blue)
 * `armv7l` (`arm32v7`) platform (Odroid HC1) running Ubuntu 18.04.1 LTS using an RTL2832U radio (FlightAware Pro Stick Plus Blue)
 * `aarch64` (`arm64v8`) platform (Raspberry Pi 4) running Raspbian Buster 64-bit using an RTL2832U radio (FlightAware Pro Stick Plus Blue)
 * If you run on a different platform (or if you have issues) please raise an issue and let me know!
 * bladeRF & plutoSDR are untested - I don't own bladeRF hardware, but support for the devices is compiled in. If you have the hardware and would be willing to test, please [open an issue on GitHub](https://github.com/mikenye/docker-readsb/issues).

## Supported tags and respective Dockerfiles
* `latest`, `v3.8.1`
  * `latest-amd64`, `3.8.0-amd64` (`3.8.1` branch, `Dockerfile.amd64`)
  * `latest-arm32v7`, `3.8.0-arm32v7` (`3.8.1` branch, `Dockerfile.arm32v7`)
  * `latest-arm64v8`, `3.8.0-arm64v8` (`3.8.1` branch, `Dockerfile.arm64v8`)
* `development` (`master` branch, `Dockerfile.amd64`, `amd64` architecture only, not recommended for production)

## Changelog

### v3.8.1
 * Original image, based on [debian:stable-slim](https://hub.docker.com/_/debian).

## Multi Architecture Support
Currently, this image should pull and run on the following architectures:
 * ```amd64```: Linux x86-64
 * ```arm32v7```, ```armv7l```: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3)
 * ```arm64v8```, ```aarch64```: ARMv8 64-bit (RPi 3B+/4)

## Prerequisites

Before this container will work properly, you must blacklist the kernel modules for the RTL-SDR USB device from the host's kernel.

To do this, create a file `/etc/modprobe.d/blacklist-rtl2832.conf` containing the following:

```
# Blacklist RTL2832 so docker container readsb can use the device

blacklist rtl2832
blacklist dvb_usb_rtl28xxu
blacklist rtl2832_sdr
```

Once this is done, you can plug in your RTL-SDR USB device and start the container.

Failure to do this will result in the error below being spammed to the container log.

```
usb_claim_interface error -6
rtlsdr: error opening the RTLSDR device: Device or resource busy
```

If you get the error above even after blacklisting the kernel modules as outlined above, the modules may still be loaded. You can unload them by running the following commands:

```
sudo rmmod rtl2832_sdr
sudo rmmod dvb_usb_rtl28xxu
sudo rmmod rtl2832
```

## Up-and-Running with `docker run`

Firstly, plug in your USB radio.

Run the command `lsusb` and find your radio. It'll look something like this:

```
Bus 001 Device 004: ID 0bda:2832 Realtek Semiconductor Corp. RTL2832U DVB-T
```

Take note of the bus number, and device number. In the output above, its 001 and 004 respectively.

Start the docker container, passing through the USB device:

```
docker run \
 -d \
 --rm \
 --name readsb \
 --device /dev/bus/usb/USB_BUS_NUMBER/USB_DEVICE_NUMBER \
 -p 8080:80 \
 mikenye/readsb \
 --dcfilter \
 --device-type=rtlsdr \
 --fix \
 --forward-mlat \
 --json-location-accuracy=2 \
 --lat=YOUR_LATITUDE \
 --lon=YOUR_LONGITUDE \
 --mlat \
 --modeac \
 --ppm=0 \
 --net \
 --stats-every=3600 \
 --quiet \
 --write-json=/var/run/readsb
```

For example, based on the `lsusb` output above:

```
docker run \
 -d \
 --rm \
 --name readsb \
 --device /dev/bus/usb/001/004 \
 -p 8080:80 \
 mikenye/readsb \
 --dcfilter \
 --device-type=rtlsdr \
 --fix \
 --forward-mlat \
 --json-location-accuracy=2 \
 --lat=-33.33333 \
 --lon=111.11111 \
 --mlat \
 --modeac \
 --ppm=0 \
 --net \
 --stats-every=3600 \
 --quiet \
 --write-json=/var/run/readsb 
```

At this point, you can test to ensure the container is correctly receiving ADSB traffic by issuing the command:

```
docker exec -it readsb viewadsb
```

Which should display a departure-lounge-style screen showing all the aircraft being tracked, for example:

```
 Hex    Mode  Sqwk  Flight   Alt    Spd  Hdg    Lat      Long   RSSI  Msgs  Ti -
────────────────────────────────────────────────────────────────────────────────
 7C801C S                     8450  256  296                   -28.0    14  1
 7C8148 S                     3900                             -21.5    19  0
 7C7A48 S     1331  VOZ471   28050  468  063  -31.290  117.480 -26.8    48  0
 7C7A4D S     3273  VOZ694   13100  376  077                   -29.1    14  1
 7C7A6E S     4342  YGW       1625  109  175  -32.023  115.853  -5.9    71  0
 7C7A71 S           YGZ        725   64  167  -32.102  115.852 -27.1    26  0
 7C42D1 S                    32000  347  211                   -32.0     4  1
 7C42D5 S                    33000  421  081  -30.955  118.568 -28.7    15  0
 7C42D9 S     4245  NWK1643   1675  173  282  -32.043  115.961 -13.6    60  0
 7C431A S     3617  JTE981   24000  289  012                   -26.7    41  0
 7C1B2D S     3711  VOZ9242  11900  294  209  -31.691  116.118  -9.5    65  0
 7C5343 S           QQD      20000  236  055  -30.633  116.834 -25.5    27  0
 7C6C96 S     1347  JST116   24000  397  354  -30.916  115.873 -17.5    62  0
 7C6C99 S     3253  JST975    2650  210  046  -31.868  115.993  -2.5    70  0
 76CD03 S     1522  SIA214     grnd   0                        -22.5     7  0
 7C4513 S     4220  QJE1808   3925  282  279  -31.851  115.887  -1.9    35  0
 7C4530 S     4003  NYA      21925  229  200  -30.933  116.640 -19.8    58  0
 7C7533 S     3236  XFP       4300  224  266  -32.066  116.124  -6.9    74  0
 7C4D44 S     3730  PJQ      20050  231  199  -31.352  116.466 -20.1    62  0
 7C0559 S     3000  BCB       1000                             -18.4    28  0
 7C0DAA S     1200            2500  146  002  -32.315  115.918 -26.6    48  0
 7C6DD7 S     1025  QFA793   17800  339  199  -31.385  116.306  -8.7    53  0
 8A06F0 S     4131  AWQ544    6125  280  217  -32.182  116.143 -12.6    61  0
 7CF7C4 S           PHRX1A                                     -13.7     8  1
 7CF7C5 S           PHRX1B                                     -13.3     9  1
 7C77F6 S           QFA595     grnd 112  014                   -33.2     2  2
```

Press CTRL-C to escape this screen.

You should also be able to point your web browser at http://dockerhost:8080/ to view the web interface. At the time of writing this readme (readsb v3.8.1), the webapp is still being actively developed. I was able to get a usable interface with Firefox.


## Up-and-Running with Docker Compose

Firstly, plug in your USB radio.

Run the command `lsusb` and find your radio. It'll look something like this:

```
Bus 001 Device 004: ID 0bda:2832 Realtek Semiconductor Corp. RTL2832U DVB-T
```

Take note of the bus number, and device number. In the output above, its 001 and 004 respectively. This is used in the `devices:` section of the `docker-compose.xml`. Change these in your environment as required.

An example `docker-compose.xml` file is below:

```
version: '2.0'

networks:
  adsbnet:

volumes:
  readsbjsondata:

services:
  
  readsb:
    image: mikenye/readsb:latest
    tty: true
    container_name: readsb
    restart: always
    devices:
      - /dev/bus/usb/001/007:/dev/bus/usb/001/007
    ports:
      - 8080:80
    networks:
      - adsbnet
    volumes:
      - readsbjsondata:/var/run/readsb
    command:
      - --dcfilter
      - --device-type=rtlsdr
      - --fix
      - --forward-mlat
      - --json-location-accuracy=2
      - --lat=-33.33333
      - --lon=111.11111
      - --mlat
      - --modeac
      - --ppm=0
      - --net
      - --stats-every=3600
      - --quiet
      - --write-json=/var/run/readsb
```

The reason for creating a specific docker network and volume makes it easier to feed data into other containers. This will be explained further below.

## Runtime Command Line Arguments

To get a list of command line arguments, you can issue the following command:

```
docker run --rm -it mikenye/readsb --help
```

The command line variables given in the examples above should work for the vast majority of ADSB set-ups.

## Ports

The following default ports are used by readsb and this container:

* `80` - readsb webapp - optional but recommended so you can look at the pretty maps and watch the planes fly around.
* `30001` - readsb TCP raw input listen port - optional, recommended to leave unmapped unless explicitly needed
* `30002` - readsb TCP raw output listen port - optional, recommended to leave unmapped unless explicitly needed
* `30003` - readsb TCP BaseStation output listen port - optional, recommended to leave unmapped unless explicitly needed
* `30004` - readsb TCP Beast input listen port - optional, recommended to leave unmapped unless explicitly needed
* `30005` - readsb TCP Beast output listen port - optional but recommended to allow other applications to receive the data provided by readsb
* `30104` - readsb TCP Beast input listen port - optional, recommended to leave unmapped unless explicitly needed

## Logging
All logs are to the container's log. It is recommended to enable docker log rotation to prevent container logs from filling up your hard drive. See https://success.docker.com/article/how-to-setup-log-rotation-post-installation for details on how to achieve this.

