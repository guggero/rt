#!/bin/bash

THIS_FILE="$(realpath "${BASH_SOURCE[0]}")"
DIR="$(cd "$( dirname "${THIS_FILE}" )" && pwd)"
DATA_DIR=${DIR}/data

if which docker-compose > /dev/null; then
  COMPOSE="docker-compose -f $DIR/regtest.yml -p regtest"
else
  COMPOSE="docker compose -f $DIR/regtest.yml -p regtest"
fi

mkdir -p "$DATA_DIR"
# shellcheck source=/dev/null
source "$DIR/functions.sh"

function stop() {
  DATA_DIR=${DATA_DIR} $COMPOSE down --volumes
}

function copymacaroons() { 
  # Save all macaroons and TLS certs to a folder outside of docker so we can use
  # them from the IDE.
  rm -rf "$DATA_DIR"/{alice,bob,charlie,dave,erin,fabia,rusty}
  mkdir -p "$DATA_DIR"/{alice,bob,charlie,dave,erin,fabia,rusty}
 
  docker cp alice:/root/.lnd/data/chain/bitcoin/regtest/. "$DATA_DIR"/alice/
  docker cp alice:/root/.lnd/tls.cert "$DATA_DIR"/alice/tls.cert

  docker cp bob:/root/.lnd/data/chain/bitcoin/regtest/. "$DATA_DIR"/bob/
  docker cp bob:/root/.lnd/tls.cert "$DATA_DIR"/bob/tls.cert

  docker cp charlie:/root/.lnd/data/chain/bitcoin/regtest/. "$DATA_DIR"/charlie/
  docker cp charlie:/root/.lnd/tls.cert "$DATA_DIR"/charlie/tls.cert

  docker cp dave:/root/.lnd/data/chain/bitcoin/regtest/. "$DATA_DIR"/dave/
  docker cp dave:/root/.lnd/tls.cert "$DATA_DIR"/dave/tls.cert
  
  docker cp erin:/root/.lnd/data/chain/bitcoin/regtest/. "$DATA_DIR"/erin/
  docker cp erin:/root/.lnd/tls.cert "$DATA_DIR"/erin/tls.cert

  docker cp fabia:/root/.lnd/data/chain/bitcoin/regtest/. "$DATA_DIR"/fabia/
  docker cp fabia:/root/.lnd/tls.cert "$DATA_DIR"/fabia/tls.cert
}

function mine() {
  # Try to use the value of the first argument passed to the function
  # if `mine` was called without any argument use the default value (6).
  NUMBLOCKS="${1-6}"
  reg_bitcoin generatetoaddress "$NUMBLOCKS" "$(reg_bitcoin getnewaddress "" legacy)" > /dev/null
}

function connectnodes() {
  echo "Getting node public keys.." 
  ALICE=$(reg_alice getinfo | jq .identity_pubkey -r)
  BOB=$(reg_bob getinfo | jq .identity_pubkey -r)
  CHARLIE=$(reg_charlie getinfo | jq .identity_pubkey -r)
  DAVE=$(reg_dave getinfo | jq .identity_pubkey -r)
  ERIN=$(reg_erin getinfo | jq .identity_pubkey -r)
  FABIA=$(reg_fabia getinfo | jq .identity_pubkey -r)
  RUSTY=$(reg_rusty getinfo | jq .id -r)

  echo "Alice:   $ALICE"
  echo "Bob:     $BOB"
  echo "Charlie: $CHARLIE"
  echo "Dave:    $DAVE"
  echo "Erin:    $ERIN"
  echo "Fabia:   $FABIA"
  echo "Rusty:   $RUSTY"

  # Connect up all the nodes.
  reg_alice connect "$BOB"@bob:9735
  reg_alice connect "$CHARLIE"@charlie:9735
  reg_alice connect "$DAVE"@dave:9735
  reg_alice connect "$ERIN"@erin:9735
  reg_alice connect "$FABIA"@fabia:9735
  reg_alice connect "$RUSTY"@rusty:9735
  reg_bob connect "$CHARLIE"@charlie:9735
  reg_bob connect "$DAVE"@dave:9735
  reg_bob connect "$ERIN"@erin:9735
  reg_bob connect "$FABIA"@fabia:9735
  reg_bob connect "$RUSTY"@rusty:9735
  reg_charlie connect "$DAVE"@dave:9735
  reg_charlie connect "$ERIN"@erin:9735
  reg_charlie connect "$FABIA"@fabia:9735
  reg_charlie connect "$RUSTY"@rusty:9735
  reg_dave connect "$ERIN"@erin:9735
  reg_dave connect "$FABIA"@fabia:9735
  reg_dave connect "$RUSTY"@rusty:9735
  reg_erin connect "$FABIA"@fabia:9735
  reg_erin connect "$RUSTY"@rusty:9735
  reg_fabia connect "$RUSTY"@rusty:9735
}

function fund() {
  echo "Sending 5 BTC to $1"
  ADDR=$(reg_$1 newaddress p2wkh | jq .address -r)
  reg_bitcoin sendtoaddress "$ADDR" 5
}

function fundcln() {
    echo "Sending 5 BTC to $1"
    ADDR=$(reg_$1 newaddr bech32 | jq .bech32 -r)
    reg_bitcoin sendtoaddress "$ADDR" 5
}

function sendfunds() {
  echo "Sending funds to all nodes..."
  fund alice
  fund bob
  fund charlie
  fund dave
  fund erin
  fund fabia
  fundcln rusty
}

function setup() {
  echo "Creating wallet..."
  reg_bitcoin createwallet miner

  ADDR_BTC=$(reg_bitcoin getnewaddress "" legacy)
  echo "Generating blocks to $ADDR_BTC"
  reg_bitcoin generatetoaddress 106 "$ADDR_BTC" > /dev/null
  reg_bitcoin getbalance

  sendfunds

  connectnodes

  mine
}

function waitnode() {
  while ! reg_$1 getinfo | grep -q identity_pubkey; do
    sleep 1
  done
}

function waitnodestart() {
  waitnode alice
  waitnode bob
  waitnode charlie
  waitnode dave
  waitnode erin
  waitnode fabia
  while ! reg_rusty getinfo | grep -q \"id\"; do
    sleep 1
  done
  BLOCKS=$(reg_bitcoin getblockchaininfo | jq .blocks -r)
  while [[ $(reg_rusty getinfo | jq .blockheight -r | xargs) -lt $BLOCKS ]]; do
    sleep 1
  done
}

function start() {
  pushd "$DIR" || exit
  # shellcheck source=/dev/null
  source ./pg-cert.sh
  popd || exit
  DATA_DIR=${DATA_DIR} $COMPOSE up --force-recreate -d
  echo "Waiting for all nodes to start..."
  waitnodestart
  setup
  copymacaroons
}

function restart() {
  if [[ "$1" != "" ]]; then
    DATA_DIR=${DATA_DIR} $COMPOSE stop "$1"
    DATA_DIR=${DATA_DIR} $COMPOSE up --build --force-recreate -d "$1"
    return
  fi
  stop
  start
}

function info() {
  ALICE=$(reg_alice getinfo | jq -c '{pubkey: .identity_pubkey, channels: .num_active_channels, peers: .num_peers}')
  BOB=$(reg_bob getinfo | jq -c '{pubkey: .identity_pubkey, channels: .num_active_channels, peers: .num_peers}')
  CHARLIE=$(reg_charlie getinfo | jq -c '{pubkey: .identity_pubkey, channels: .num_active_channels, peers: .num_peers}')
  DAVE=$(reg_dave getinfo | jq -c '{pubkey: .identity_pubkey, channels: .num_active_channels, peers: .num_peers}')
  ERIN=$(reg_erin getinfo | jq -c '{pubkey: .identity_pubkey, channels: .num_active_channels, peers: .num_peers}')
  FABIA=$(reg_fabia getinfo | jq -c '{pubkey: .identity_pubkey, channels: .num_active_channels, peers: .num_peers}')
  RUSTY=$(reg_rusty getinfo | jq .id -r)
  echo "Alice:   $ALICE"
  echo "Bob:     $BOB"
  echo "Charlie: $CHARLIE"
  echo "Dave:    $DAVE"
  echo "Erin:    $ERIN"
  echo "Fabia:   $FABIA"
  echo "Rusty:   $RUSTY"
}

if [ $# -lt 1 ]
then
  echo "Usage: $0 start|stop|restart|setup|info"
fi

CMD=$1
shift

# Translate calls to "rt <node>" to the "reg_<node>" function.
NODES=("bitcoin alice alice_lit bob bob_lit charlie dave erin fabia rusty")
if [[ "${NODES[*]}" =~ "$CMD" ]]; then
  reg_$CMD "$@"
  exit
fi

$CMD "$@"
