#!/usr/bin/env python3

import os
import sys
import argparse
import re
import shutil
import subprocess
import time
import json

import yaml
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper

from pprint import pprint


# GLOBALS
LOW_STRONG_MESSAGES_PERCENT=1.0
HIGH_STRONG_MESSAGES_PERCENT=5.0
SUPPORTED_GAIN_VALUES=(
    0.0, 0.9, 1.4, 2.7, 3.7, 7.7, 8.7, 12.5, 14.4, 15.7,
    16.6, 19.7, 20.7, 22.9, 25.4, 28.0, 29.7, 32.8, 33.8, 36.4,
    37.2, 38.6, 40.2, 42.1, 43.4, 43.9, 44.5, 48.0, 49.6,
    -10,
    )


def run_command(
    command_line: list,
):
    command_line_str = " ".join(command_line)
    print("Running '{command_line_str}'...".format(
        command_line_str=command_line_str,
    ))
    proc = subprocess.Popen(
        command_line,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    
    # get output or timeout after 5 mins
    try:
        outs, errs = proc.communicate(timeout=300)
    except subprocess.TimeoutExpired:
        proc.kill()
        outs, errs = proc.communicate()
    
    # stdout & stderr if there were any issues running the command
    if proc.returncode != 0:
        print(
            "ERROR: '{command_line_str}' had a returncode of '{returncode}'",
            file=sys.stderr,
            )
        print(
            "-- stdout: ------------------------------------------",
            file=sys.stderr
        )
        print(outs, file=sys.stderr)
        print(
            "-- stderr: ------------------------------------------",
            file=sys.stderr
        )
        print(errs, file=sys.stderr)
        sys.exit(1)

    # return stdout
    return outs
    

def docker_compose_up_d(
    args_file: str,
    args_project_directory: str,
):
    commandline = "docker-compose --file {file} --project-directory {project_directory} up -d".format(
        file = os.path.join(args_project_directory, args_file),
        project_directory = args_project_directory,
    )
    outs = run_command(commandline.split())
    return outs


def get_stats_json_data(
    container_name: str,
    readsb_json_path: str,
):
    commandline = "docker exec {container_name} cat {readsb_json_path}/stats.json".format(
        container_name=container_name,
        readsb_json_path=readsb_json_path,
    )
    return json.loads(run_command(commandline.split()).decode('utf-8'))


def which(program):
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None


def get_service_from_containername(
    container_name: str,
    docker_compose_yaml,
):
    service_name = None
    for d_service in docker_compose_yaml['services']:
        if docker_compose_yaml['services'][d_service]['container_name'] == container_name:
            service_name = d_service
            break

    if service_name == None:
        print(
            "ERROR: Could not find container {container_name}".format(
                container_name = container_name,
            ),
            file=sys.stderr,
        )
        sys.exit(1)

    return service_name


def get_service_commandline_value(
    service_name: str,
    re_pattern: str,
    commandline_name: str,
    docker_compose_yaml,
):
    commandline_value = None
    for d_command in docker_compose_yaml['services'][service_name]['command']:
        commandline_value_match = re.match(re_pattern, d_command)
        if commandline_value_match:
            commandline_value = commandline_value_match.group(1)
            print("Found: {commandline_arg}".format(
                commandline_arg = commandline_value_match.group(0),
            ))
    
    if commandline_value == None:
        print(
            "ERROR: Service declaration for {container_name} in is missing the '{commandline_name}' argument".format(
                container_name = args.readsb_container_name,
                commandline_name = commandline_name,
            ),
            file=sys.stderr,
        )
        sys.exit(1)

    return commandline_value

def remove_service_commandline(
    service_name: str,
    re_pattern: str,
    docker_compose_yaml,
):
    new_command_line_arg = list()
    for d_command in docker_compose_yaml['services'][service_name]['command']:
        commandline_value_match = re.match(re_pattern, d_command)
        if commandline_value_match:
            continue
        else:
            new_command_line_arg.append(d_command)        
    
    return new_command_line_arg


def main():
    parser = argparse.ArgumentParser(description='Perform automatic gain adjustment for the mikenye/readsb docker container')
    parser.add_argument(
        '--file', '-f',
        type=str,
        default="docker-compose.yml",
        help='Specify an alternate compose file (default: docker-compose.yml)',
        )
    parser.add_argument(
        '--project-directory',
        type=str,
        default=os.getcwd(),
        help='Specify an alternate project name (default: directory name)',
        )
    parser.add_argument(
        '--readsb-container-name', '-n',
        type=str,
        required=True,
        help='Specify the name of the mikenye/readsb container',
        )
    parser.add_argument(
        '--iteration-time',
        type=int,
        default=9000,
        help='Number of seconds to wait between gain changes (default: 9000 (2.5 hours))',
        )
    parser.add_argument(
        '--min-gain',
        type=float,
        default=0.0,
        help='Minimum gain figure to try (default: 0.0)',
        )
    parser.add_argument(
        '--max-gain',
        type=float,
        default=49.6,
        help='Maximum gain figure to try (default: 49.6)',
        )

    args = parser.parse_args()

    pprint(args)

    docker_compose_yaml_file = os.path.join(args.project_directory, args.file)

    # Log a warning - let user know not to make changes to docker-compose.yml while this script is running
    print("")
    print("***** WARNING: The file {docker_compose_yaml_file} must not be modified while this script runs! *****".format(
        docker_compose_yaml_file = docker_compose_yaml_file,
    ))

    print("")
    print("===== Running pre-flight checks... =====")

    # make sure we can find docker executable
    docker_bin = which('docker')

    if docker_bin == None:
        print(
            "ERROR: could not find docker, ensure your PATH variable is set correctly",
            file=sys.stderr,
        )
        sys.exit(1)
    else:
        print("Found docker!")

    # make sure we can find docker-compose executable
    docker_compose_bin = which('docker-compose')

    if docker_compose_bin == None:
        print(
            "ERROR: could not find docker-compose, ensure your PATH variable is set correctly",
            file=sys.stderr,
        )
        sys.exit(1)
    else:
        print("Found docker-compose!")

    # make sure we can open docker-compose.yml for writing
    if not os.path.isfile(docker_compose_yaml_file):
        print(
            "ERROR: {docker_compose_yaml_file} does not exist".format(
            docker_compose_yaml_file = docker_compose_yaml_file,
            ),
            file=sys.stderr,
        )
        sys.exit(1)

    # backup original docker-compose.yml file
    docker_compose_yaml_file_backup = "".join((docker_compose_yaml_file, ".original"))
    print("Backing up {docker_compose_yaml_file} to {docker_compose_yaml_file_backup}".format(
        docker_compose_yaml_file=docker_compose_yaml_file,
        docker_compose_yaml_file_backup=docker_compose_yaml_file_backup,
    ))
    shutil.copy2(docker_compose_yaml_file, docker_compose_yaml_file_backup)

    # open docker-compose.yml file
    docker_compose_yaml = yaml.load(open(docker_compose_yaml_file), Loader=Loader)

    # find the readsb service based on container name
    service_name = get_service_from_containername(
        container_name=args.readsb_container_name,
        docker_compose_yaml=docker_compose_yaml,
    )
    print("Found readsb service: {readsb_service}".format(
            readsb_service=service_name,
    ))

    # find "command:" section
    if 'command' not in docker_compose_yaml['services'][service_name]:
        print(
            "ERROR: Service declaration for {container_name} in {docker_compose_yaml_file} is missing the 'command:' section".format(
                container_name = args.readsb_container_name,
                docker_compose_yaml_file = docker_compose_yaml_file,
            ),
            file=sys.stderr,
        )
        sys.exit(1)
    else:
        print("Found 'command:' section")

    # find current "--gain" argument and log it
    re_pattern_gain_arg = r'^--gain=([\-\d\.]+)$'
    original_gain = get_service_commandline_value(
        service_name=service_name,
        re_pattern=re_pattern_gain_arg,
        commandline_name="--gain",
        docker_compose_yaml=docker_compose_yaml,
    )

    # find current "--write-json" argument and log it
    re_pattern_writejson_arg = r'^--write-json=(.+)$'
    readsb_json_path = get_service_commandline_value(
        service_name=service_name,
        re_pattern=re_pattern_writejson_arg,
        commandline_name="--write-json",
        docker_compose_yaml=docker_compose_yaml,
    )
    
    # TODO: make sure we can get stats.json
    results_dict = dict()
    for gain_value in SUPPORTED_GAIN_VALUES:

        # skip gain values outside of min/max range specified on command line
        if gain_value < args.min_gain:
            continue
        elif gain_value > args.max_gain:
            continue
        else:

            print("")
            print("===== Testing with gain: {gain_value} =====".format(
                gain_value=gain_value,
            ))

            # pull out existing "--gain" argument
            docker_compose_yaml['services'][service_name]['command'] = remove_service_commandline(
                service_name=service_name,
                re_pattern=re_pattern_gain_arg,
                docker_compose_yaml=docker_compose_yaml,
            )

            # insert new "--gain" argument
            docker_compose_yaml['services'][service_name]['command'].append(
                "--gain={gain_value}".format(gain_value=gain_value),
            )

            # save updated yaml
            with open(docker_compose_yaml_file, 'w') as f:
                f.write(
                    yaml.dump(
                        docker_compose_yaml,
                        Dumper=Dumper,
                        default_flow_style=False,
                    )
                )

            # docker-compose up -d
            docker_compose_up_d(
                args_file = args.file,
                args_project_directory = args.project_directory,
            )

            # wait for results
            print("Waiting {iteration_time} seconds for results collection...".format(
                iteration_time = args.iteration_time,
            ))
            time.sleep(args.iteration_time)

            # get stats.json data
            stats_json_data = get_stats_json_data(
                container_name = args.readsb_container_name,
                readsb_json_path = readsb_json_path,
            )

            # get metrics from results
            strong = stats_json_data['total']['local']['strong_signals']
            total = stats_json_data['total']['local']['accepted'][0]
            percent_strong = 0.0
            if total == 0.0:
                print("No messages received!")
            else:
                percent_strong = round((float(strong) / float(total)) * 100, 2)
                print("Total messages: {total}".format(total=total))
                print("Strong messages: {percent_strong}".format(percent_strong=percent_strong))
                print("Percentage strong messages: {percent_strong}".format(
                    percent_strong=percent_strong,
                ))

            # add results into results_dict
            results_dict[gain_value] = dict()
            results_dict[gain_value]['strong'] = strong
            results_dict[gain_value]['total'] = total
            results_dict[gain_value]['percent_strong'] = percent_strong

    print("")
    print("===== Restoring original settings =====")

    # Restore from backup
    print("Restoring {docker_compose_yaml_file} from backup {docker_compose_yaml_file_backup}".format(
        docker_compose_yaml_file=docker_compose_yaml_file,
        docker_compose_yaml_file_backup=docker_compose_yaml_file_backup,
    ))
    shutil.copy2(docker_compose_yaml_file_backup, docker_compose_yaml_file)

    # docker-compose up -d
    docker_compose_up_d(
        args_file = args.file,
        args_project_directory = args.project_directory,
    )

    print("")
    print("===== RESULTS: =====")
    pprint(results_dict)

    print ("")


if __name__ == "__main__":
    main()
