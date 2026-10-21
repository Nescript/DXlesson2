#!/usr/bin/env bash
set -eo pipefail
course=$(cd "$(dirname "$0")/.." && pwd)
demos=${1:-"$course/demos"}
source /opt/ros/noetic/setup.bash
work=$(mktemp -d)
master_pid=
node_pid=
cleanup() {
    for pid in "$node_pid" "$master_pid"; do
        if [[ -n "$pid" ]]; then kill -INT "$pid" 2>/dev/null || true; fi
    done
    sleep 1
    for pid in "$node_pid" "$master_pid"; do
        if [[ -n "$pid" ]]; then
            kill -TERM "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
    rm -rf -- "$work"
}
trap cleanup EXIT
cp -R "$demos/05_catkin/workspace" "$work/workspace"
cd "$work/workspace"
catkin_make -j2 -l2
source devel/setup.bash
export ROS_HOME="$work/ros-home"
export ROS_LOG_DIR="$work/ros-logs"
export ROS_IP=127.0.0.1
unset ROS_HOSTNAME
port=$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    print(sock.getsockname()[1])
PY
)
export ROS_MASTER_URI="http://127.0.0.1:$port"
roscore -p "$port" > "$work/master.log" 2>&1 &
master_pid=$!
ready=false
for attempt in {1..30}; do
    if timeout 2s rosparam list > /dev/null 2>&1; then ready=true; break; fi
    sleep 0.2
done
if [[ "$ready" != true ]]; then cat "$work/master.log"; exit 1; fi
rosrun add_demo add_node > "$work/node.log" 2>&1 &
node_pid=$!
message=$(timeout 20s rostopic echo -n1 /lesson2/sum)
printf '%s\n' "$message"
grep -q '^data: 3$' <<< "$message"
echo 'PASS: catkin builds one package; add_node publishes data: 3.'
