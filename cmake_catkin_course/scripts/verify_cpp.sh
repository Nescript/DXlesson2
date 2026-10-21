#!/usr/bin/env bash
set -euo pipefail
course=$(cd "$(dirname "$0")/.." && pwd)
demos=${1:-"$course/demos"}
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cp -R "$demos/." "$work/"

check_output() { test "$("$1")" = 3; }
cd "$work/01_single_file"
g++ main.cpp -o demo
check_output ./demo

cd "$work/02_multi_manual"
g++ main.cpp add.cpp -o demo
check_output ./demo
g++ -c main.cpp
g++ -c add.cpp
if g++ main.o -o missing_demo > error.log 2>&1; then
    echo 'Expected the incomplete link to fail' >&2
    exit 1
fi
g++ main.o add.o -o demo
check_output ./demo

cd "$work/03_makefile"
make
check_output ./demo
make -q
sleep 1
touch add.cpp
make -n > plan.log
grep -q 'g++ -c add.cpp' plan.log
if grep -q 'g++ -c main.cpp' plan.log; then exit 1; fi
make
sleep 1
touch add.h
make -n > plan.log
grep -q 'g++ -c main.cpp' plan.log
grep -q 'g++ -c add.cpp' plan.log
make

cd "$work/04_cmake"
cmake -S . -B build
cmake --build build --parallel 2
check_output ./build/demo
echo 'PASS: all four C++ demos print 3; manual linking and Make dependencies work.'
