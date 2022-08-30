#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 hostname"
    exit 1;
fi

HOST=$1
cd data/secrets/provision_key/
rm -f $HOST.pub $HOST.gpg
ssh-keygen -P "" -f $HOST -t ed25519
gpg -q -c --passphrase-file ./provision_key_password --batch $HOST
srm $HOST

