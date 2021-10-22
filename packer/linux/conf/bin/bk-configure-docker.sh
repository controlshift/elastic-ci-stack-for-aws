#!/bin/bash
# shellcheck disable=SC2094
set -euo pipefail

## Configures docker before system starts

# Write to system console and to our log file
# See https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee -a /var/log/elastic-stack.log|logger -t user-data -s 2>/dev/console) 2>&1

# Set user namespace remapping in config
if [[ "${DOCKER_USERNS_REMAP:-false}" == "true" ]] ; then
  cat <<< "$(jq '."userns-remap"="buildkite-agent"' /etc/docker/daemon.json)" > /etc/docker/daemon.json
fi

# Set experimental in config
if [[ "${DOCKER_EXPERIMENTAL:-false}" == "true" ]] ; then
  cat <<< "$(jq '.experimental=true' /etc/docker/daemon.json)" > /etc/docker/daemon.json
fi

# Move docker root to the ephemeral device
if [[ "${BUILDKITE_ENABLE_INSTANCE_STORAGE:-false}" == "true" ]] ; then
  cat <<< "$(jq '."data-root"="/mnt/ephemeral/docker"' /etc/docker/daemon.json)" > /etc/docker/daemon.json
fi

# restart the docker service to ensure config file is read in.
sudo systemctl restart docker

# wait for docker to start
next_wait_time=0
until docker ps || [ $next_wait_time -eq 5 ]; do
	sleep $(( next_wait_time++ ))
done

if ! docker ps ; then
  echo "Failed to contact docker"
  exit 1
fi

# allow failures while warming the images we use.
docker pull circleci/postgres:12-postgis-ram || true
docker pull ruby:2.7.4-alpine || true
docker pull docker.elastic.co/elasticsearch/elasticsearch:7.9.3 || true
docker pull circleci/redis:6-alpine || true
