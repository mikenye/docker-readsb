# mikenye/readsb

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-readsb/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-readsb/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/readsb.svg)](https://hub.docker.com/r/mikenye/readsb)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/readsb/latest)](https://hub.docker.com/r/mikenye/readsb)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)


[Mictronics' `readsb`](https://github.com/Mictronics/readsb) Mode-S/ADSB/TIS decoder for RTLSDR, BladeRF, Modes-Beast and GNS5894 devices, running in a docker container.

Support for RTLSDR, bladeRF and plutoSDR is compiled in. Builds and runs on x86, x86_64, arm32v6, arm32v7 and arm64.

This image will configure a software-defined radio (SDR) to receive and decode Mode-S/ADSB/TIS data from aircraft within range, for use with other services such as:

* `mikenye/adsbexchange` to feed ADSB data to [adsbexchange.com](https://adsbexchange.com)
* `mikenye/piaware` to feed ADSB data into [flightaware.com](https://flightaware.com)
* `mikenye/fr24feed` to feed ADSB data into [flightradar24.com](https://www.flightradar24.com)
* `mikenye/piaware-to-influx` to feed data into your own instance of [InfluxDB](https://docs.influxdata.com/influxdb/), for visualisation with [Grafana](https://grafana.com) and/or other tools
* Any other tools that can receive Beast, BeastReduce, Basestation or the raw data feed from `readsb` or `dump1090` and their variants

bladeRF & plutoSDR are untested - I don't own bladeRF or plutoSDR hardware (only RTL2832U as outlined above), but support for the devices is compiled in. If you have the hardware and would be willing to test, please [open an issue on GitHub](https://github.com/mikenye/docker-readsb/issues).

## Deprecation notice

The author of `readsb` (Mictronics) is no longer developing `readsb`, and instead all future development efforts will go into the Protocol Buffer version (`readsb-protobuf`) starting with version v4.0.0 (see [here](https://github.com/Mictronics/readsb#no-longer-under-development)).

I would recommend migrating to the container: [`mikenye/readsb-protobuf`](https://github.com/mikenye/docker-readsb-protobuf) instead of continuing to use this container.

## Supported tags and respective Dockerfiles

* `latest` should always contain the latest released versions of `rtl-sdr`, `bladeRF`, `libiio`, `libad9361-iio` and `readsb`. This image is built nightly from the [`master` branch](https://github.com/mikenye/docker-readsb) [`Dockerfile`](https://github.com/mikenye/docker-readsb/blob/master/Dockerfile) for all supported architectures.
* `latest_nohealthcheck` is the same as the `latest` version above. However, this version has the docker healthcheck removed. This is done for people running platforms (such as [Nomad](https://www.nomadproject.io)) that don't support manually disabling healthchecks, where healthchecks are not wanted.
* Specific version and architecture tags are available if required, however these are not regularly updated. It is generally recommended to run `latest`.

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* ```amd64```: Linux x86-64
* ```arm32v7```, ```armv7l```: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3)
* ```arm64v8```, ```aarch64```: ARMv8 64-bit (RPi 3B+/4)

## Prerequisites

Before this container will work properly, you must blacklist the kernel modules for the RTL-SDR USB device from the host's kernel.

To do this, create a file `/etc/modprobe.d/blacklist-rtl2832.conf` containing the following:

```shell
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

```shell
sudo rmmod rtl2832_sdr
sudo rmmod dvb_usb_rtl28xxu
sudo rmmod rtl2832
```

## Healthcheck

In order for the container's health check to be the most effective, you should be sure to include `--write-json=/run/readsb`.

If the healthcheck script can't find `/run/readsb/aircraft.json`, it will skip some checks.

## Up-and-Running with `docker run`

Firstly, plug in your USB radio.

Run the command `lsusb` and find your radio. It'll look something like this:

```
Bus 001 Device 004: ID 0bda:2832 Realtek Semiconductor Corp. RTL2832U DVB-T
```

Take note of the bus number, and device number. In the output above, its 001 and 004 respectively.

Start the docker container, passing through the USB device:

```shell
docker run \
 -d \
 --rm \
 --name readsb \
 --device /dev/bus/usb/USB_BUS_NUMBER/USB_DEVICE_NUMBER \
 -p 8080:8080 \
 -p 30005:30005 \
 -e TZ=YOURTIMEZONE \
 mikenye/readsb \
 --dcfilter \
 --device-type=rtlsdr \
 --fix \
 --json-location-accuracy=2 \
 --lat=YOUR_LATITUDE \
 --lon=YOUR_LONGITUDE \
 --modeac \
 --ppm=0 \
 --net \
 --stats-every=3600 \
 --quiet \
 --write-json=/run/readsb
```

For example, based on the `lsusb` output above:

```shell
docker run \
 -d \
 --rm \
 --name readsb \
 --device /dev/bus/usb/001/004 \
 -p 8080:8080 \
 -p 30005:30005 \
 -e TZ=Australia/Perth \
 mikenye/readsb \
 --dcfilter \
 --device-type=rtlsdr \
 --fix \
 --json-location-accuracy=2 \
 --lat=-33.33333 \
 --lon=111.11111 \
 --modeac \
 --ppm=0 \
 --net \
 --stats-every=3600 \
 --quiet \
 --write-json=/run/readsb
```

## Up-and-Running with Docker Compose

Firstly, plug in your USB radio.

Run the command `lsusb` and find your radio. It'll look something like this:

```shell
Bus 001 Device 004: ID 0bda:2832 Realtek Semiconductor Corp. RTL2832U DVB-T
```

Take note of the bus number, and device number. In the output above, its 001 and 004 respectively. This is used in the `devices:` section of the `docker-compose.yml`. Change these in your environment as required.

An example `docker-compose.yml` file is below:

```yaml
version: '2.0'

networks:
  adsbnet:

services:

  readsb:
    image: mikenye/readsb:latest
    tty: true
    container_name: readsb
    restart: always
    devices:
      - /dev/bus/usb/001/007:/dev/bus/usb/001/007
    ports:
      - 8080:8080
      - 30005:30005
    networks:
      - adsbnet
    environment:
      - TZ=Australia/Perth
    command:
      - --dcfilter
      - --device-type=rtlsdr
      - --fix
      - --json-location-accuracy=2
      - --lat=-33.33333
      - --lon=111.11111
      - --modeac
      - --ppm=0
      - --net
      - --stats-every=3600
      - --quiet
      - --write-json=/run/readsb
```

The reason for creating a specific docker network and volume makes it easier to feed data into other containers. This will be explained further below.

## Testing the container

Once running, you can test the container to ensure it is correctly receiving & decoding ADSB traffic by issuing the command:

```shell
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

Press `CTRL-C` to escape this screen.

You should also be able to point your web browser at `http://dockerhost:8080/` to view the web interface. At the time of writing this readme (readsb v3.8.1), the webapp is still being actively developed. I was able to get a usable interface with Firefox.

## Runtime Command Line Arguments

To get a list of command line arguments, you can issue the following command:

```shell
docker run --rm -it mikenye/readsb --help
```

The command line variables given in the examples above should work for the vast majority of ADSB set-ups.

## "MLAT Hub" Functionality

The command line argument `PULLMLAT` can be specified with the syntax of: `MLATHOST:MLATPORT[,MLATHOST:MLATPORT,...]`.

If set, then a separate instance of `readsb` will be started in `--net-only` mode, configured to pull MLAT data from `mlat-client`s running on other containers, listen on TCP port `30105` and forward MLAT data to any clients that connect on this port. This may be useful for tools such as [`graphs1090`](https://hub.docker.com/r/mikenye/graphs1090) and/or [`tar1090`](https://hub.docker.com/r/mikenye/tar1090).

For example:

```yaml
...
    environment:
      - PULLMLAT=piaware:30105,adsbx:30105,rbfeeder:30105
...
```

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                         | Default |
| -------------------- | ------------------------------- | ------- |
| `TZ`                 | Your local timezone (recommended)  | UTC     |
| `PULLMLAT`           | See above (optional)            |         |

## Ports

The following default ports are used by readsb and this container:

* `8080` - readsb webapp - optional but recommended so you can look at the pretty maps and watch the planes fly around. For the web interface to function, you must include the command line argument `--write-json=/run/readsb`.
* `30001` - readsb TCP raw input listen port - optional, recommended to leave unmapped unless explicitly needed
* `30002` - readsb TCP raw output listen port - optional, recommended to leave unmapped unless explicitly needed
* `30003` - readsb TCP BaseStation output listen port - optional, recommended to leave unmapped unless explicitly needed
* `30004` - readsb TCP Beast input listen port - optional, recommended to leave unmapped unless explicitly needed
* `30005` - readsb TCP Beast output listen port - optional but recommended to allow other applications to receive the data provided by readsb
* `30104` - readsb TCP Beast input listen port - optional, recommended to leave unmapped unless explicitly needed
* `30105` - readsb TCP "MLAT Hub" Beast output port - optional. See *"MLAT Hub" Functionality* above.

## Logging

All logs are to the container's log. It is recommended to enable docker log rotation to prevent container logs from filling up your hard drive. See [Configure the default logging driver](https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver) for details on how to achieve this.

## Getting help

Please feel free to [open an issue on the project's GitHub](https://github.com/mikenye/docker-readsb/issues).

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.

## Changelog

See the project's [commit history](https://github.com/mikenye/docker-readsb/commits/master).
