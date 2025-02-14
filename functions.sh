#!/bin/bash

# This file is intended to be sourced directly into your `~/.bashrc` file as
# well as within `rt/regtest.sh`.
# So if you source this into your `.bashrc` file, you can use all the commands
# here directly or through the `regtest.sh` script. When using the `regtest.sh`
# script (symlinked to /usr/local/bin/rt), you can drop the `reg_` prefix from
# the commands. So you can just type `rt bitcoin` instead of `reg_bitcoin`.

TTY_FLAG="-ti"

if [ "$NOTTY" = "1" ]; then
  TTY_FLAG=""
fi

function reg_bitcoin() {
  docker exec $TTY_FLAG -u bitcoin bitcoind bitcoin-cli -regtest -rpcuser=lightning -rpcpassword=lightning "$@"
}

function reg_alice() {
  docker exec $TTY_FLAG alice lncli --network regtest "$@"
}

function reg_alice_litcli() {
  docker exec $TTY_FLAG alice litcli --network regtest "$@"
}

function reg_alice_loop() {
  docker exec $TTY_FLAG alice loop --network regtest --rpcserver localhost:8443 --tlscertpath /root/.lit/tls.cert --loopdir /root/.loop "$@"
}

function reg_alice_tapcli() {
  docker exec $TTY_FLAG alice tapcli --network regtest --rpcserver localhost:8443 --tlscertpath /root/.lit/tls.cert --tapddir /root/.tapd "$@"
}

function reg_bob() {
  docker exec $TTY_FLAG bob lncli --network regtest "$@"
}

function reg_bob_litcli() {
  docker exec $TTY_FLAG bob litcli --network regtest "$@"
}

function reg_bob_loop() {
  docker exec $TTY_FLAG bob loop --network regtest --rpcserver localhost:8443 --tlscertpath /root/.lit/tls.cert --loopdir /root/.loop "$@"
}

function reg_bob_tapcli() {
  docker exec $TTY_FLAG bob tapcli --network regtest --rpcserver localhost:8443 --tlscertpath /root/.lit/tls.cert --tapddir /root/.tapd "$@"
}

function reg_charlie() {
  docker exec $TTY_FLAG charlie lncli --network regtest "$@"
}

function reg_dave() {
  docker exec $TTY_FLAG dave lncli --network regtest "$@"
}

function reg_erin() {
  docker exec $TTY_FLAG erin lncli --network regtest "$@"
}

function reg_fabia() {
  docker exec $TTY_FLAG fabia lncli --network regtest "$@"
}

function reg_nifty() {
  docker exec $TTY_FLAG nifty lightning-cli --network regtest "$@"
}

function reg_rusty() {
  docker exec $TTY_FLAG rusty lightning-cli --network regtest "$@"
}

function reg_snyke() {
  docker exec $TTY_FLAG snyke lightning-cli --network regtest "$@"
}
