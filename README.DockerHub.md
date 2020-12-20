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

## Documentation

Please [read this container's detailed and thorough documentation in the GitHub repository.](https://github.com/mikenye/docker-readsb/blob/master/README.md)