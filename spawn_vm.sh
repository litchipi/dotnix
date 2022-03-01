#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <machine name>"
    exit 1;
fi

MACHINE=$1
shift 1;

OPTS="-smp $(nproc) -m 8G -device virtio-net,netdev=vmnic -netdev user,id=vmnic"

nix build .#$MACHINE.clivm

cd ./result
set +e
sudo ./bin/run-nixostest-vm $OPTS $@
cd ..
