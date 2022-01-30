#!/bin/bash

set -e

gpg -d gitcrypt.key.gpg > gitcrypt.key
git-crypt unlock gitcrypt.key
srm gitcrypt.key
