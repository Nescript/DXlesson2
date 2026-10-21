#!/usr/bin/env bash
set -euo pipefail
source /etc/os-release
printf 'OS=%s\n' "$PRETTY_NAME"
for tool in g++ make cmake ninja; do
    command -v "$tool" || true
done
g++ --version | head -n 1
make --version | head -n 1
cmake --version | head -n 1
if [[ -f /opt/ros/noetic/setup.bash ]]; then
    set +u
    source /opt/ros/noetic/setup.bash
    set -u
    printf 'ROS_DISTRO=%s\n' "$ROS_DISTRO"
    for tool in catkin_make roscore roslaunch rostopic; do
        command -v "$tool"
    done
    rosversion roscpp
fi
