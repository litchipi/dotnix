#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <machine name>"
    exit 1;
fi

MACHINE=$1
shift 1;

OPTS="-cpu host -smp $(nproc) -m 8G -machine accel=kvm"

nix build .#$MACHINE.clivm

mkdir -p ./vm_disk/$MACHINE
cd ./vm_disk/$MACHINE

set +e
sudo ../../result/bin/run-nixostest-vm $OPTS $@
cd ..
