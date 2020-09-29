# Helper Scripts

## `measuregain.py`

This script is based on the discussions here: <https://discussions.flightaware.com/t/thoughts-on-optimizing-gain/44482/2>.

It will modify your `docker-compose.yml` file and run `readsb` for 2.5 hours (by default) with each allowable gain setting.

The script will then output the following statistics for each gain level:

* Total number of messages
* Number of strong messages
* Percentage of strong messages

You're aiming for 1-5% of strong messages.

While running, the `docker-compose.yml` must not be modified by any other process/user.

### Syntax

```
usage: measuregain.py [-h] [--file FILE]
                      [--project-directory PROJECT_DIRECTORY]
                      --readsb-container-name READSB_CONTAINER_NAME
                      [--iteration-time ITERATION_TIME] [--min-gain MIN_GAIN]
                      [--max-gain MAX_GAIN]

Perform automatic gain adjustment for the mikenye/readsb docker container

optional arguments:
  -h, --help            show this help message and exit
  --file FILE, -f FILE  Specify an alternate compose file (default: docker-
                        compose.yml)
  --project-directory PROJECT_DIRECTORY
                        Specify an alternate project name (default: directory
                        name)
  --readsb-container-name READSB_CONTAINER_NAME, -n READSB_CONTAINER_NAME
                        Specify the name of the mikenye/readsb container
  --iteration-time ITERATION_TIME
                        Number of seconds to wait between gain changes
                        (default: 9000 (2.5 hours))
  --min-gain MIN_GAIN   Minimum gain figure to try (default: 0.0)
  --max-gain MAX_GAIN   Maximum gain figure to try (default: 49.6)
```

### Instructions

Change directory to your `docker-compose.yml` file associated with your ADS-B environment.

```bash
cd /opt/adsb
```

Take a backup of your `docker-compose.yml` file:

```bash
cp -v ./docker-compose.yml ./docker-compose.yml.backup.$(date -Iminutes)
```

Download the gain measurement script:

```bash
curl -O https://raw.githubusercontent.com/mikenye/docker-readsb/master/scripts/measuregain.py
```

Run the gain measurement script:

```bash
python3 measuregain.py -n readsb
```

...where `readsb` is the name of your `mikenye/readsb` container.

This script will take ~75 hours to complete with the default settings.

Choose a gain level that gives you between 1-5% of strong messages.
