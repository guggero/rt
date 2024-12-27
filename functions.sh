#!/bin/bash

# This file is intended to be sourced directly into your `~/.bashrc` file as
# well as within `rt/regtest.sh`.
# So if you source this into your `.bashrc` file, you can use all the commands
# here directly or through the `regtest.sh` script. When using the `regtest.sh`
# script (symlinked to /usr/local/bin/rt), you can drop the `reg_` prefix from
# the commands. So you can just type `rt bitcoin` instead of `reg_bitcoin`.

function reg_bitcoin() {
  docker exec -ti -u bitcoin bitcoind bitcoin-cli -regtest -rpcuser=lightning -rpcpassword=lightning "$@"
}

function reg_alice() {
  docker exec -ti alice lncli --network regtest "$@"
}

function reg_alice_lit() {
  docker exec -ti alice litcli --network regtest "$@"
}

function reg_bob() {
  docker exec -ti bob lncli --network regtest "$@"
}

function reg_bob_lit() {
  docker exec -ti bob litcli --network regtest "$@"
}

function reg_charlie() {
  docker exec -ti charlie lncli --network regtest "$@"
}

function reg_dave() {
  docker exec -ti dave lncli --network regtest "$@"
}

function reg_erin() {
  docker exec -ti erin lncli --network regtest "$@"
}

function reg_fabia() {
  docker exec -ti fabia lncli --network regtest "$@"
}

function reg_rusty() {
  docker exec -ti rusty lightning-cli --network regtest "$@"
}
