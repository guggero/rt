#!/bin/bash

function solution1() {
  rt fund alice 10
  rt fund bob 10
  rt fund charlie 10
  rt fund dave 10
  rt fund erin 10
  rt fund fabia 10
  rt fund nifty 10
  rt fund rusty 10
  rt fund snyke 10
  rt mine 1
  rt waitnodestart
}

function solution2() {
  ALICE=$(rt alice getinfo | jq .identity_pubkey -r)
  BOB=$(rt bob getinfo | jq .identity_pubkey -r)
  CHARLIE=$(rt charlie getinfo | jq .identity_pubkey -r)
  DAVE=$(rt dave getinfo | jq .identity_pubkey -r)
  ERIN=$(rt erin getinfo | jq .identity_pubkey -r)
  FABIA=$(rt fabia getinfo | jq .identity_pubkey -r)
  NIFTY=$(rt nifty getinfo | jq .id -r)
  RUSTY=$(rt rusty getinfo | jq .id -r)
  SNYKE=$(rt snyke getinfo | jq .id -r)
  
  rt alice openchannel --node_key $BOB --local_amt 100000000
  rt bob openchannel --node_key $NIFTY --local_amt 100000000
  rt nifty fundchannel $DAVE 100000000
  rt dave openchannel --node_key $FABIA --local_amt 100000000
  rt fabia openchannel --node_key $ERIN --local_amt 100000000
  rt mine 1
  rt fabia openchannel --node_key $SNYKE --local_amt 100000000
  rt snyke fundchannel $BOB 100000000
  rt erin openchannel --node_key $ALICE --local_amt 100000000
  rt mine 6
  rt info
}

function solution3() {
  rt waitnodestart
  INVOICE=$(rt fabia addinvoice 50000 | jq -r '.payment_request')
  rt alice payinvoice -f $INVOICE
  HASH=$(rt fabia decodepayreq $INVOICE | jq -r '.payment_hash')
  PAYMENTS=$(rt alice listpayments)
  echo $PAYMENTS | jq --indent 1 -r '.payments[] | select(.payment_hash == "'$HASH'")'
}

function solution4() {
  BOB=$(rt bob getinfo | jq .identity_pubkey -r)
  rt fabia sendpayment --keysend --dest $BOB --amt 5000
}

function solution5() {
  ALICE=$(rt alice getinfo | jq .identity_pubkey -r)
  ERIN=$(rt erin getinfo | jq .identity_pubkey -r)
  rt alice sendpayment --keysend --dest $ALICE --allow_self_payment --last_hop $ERIN  30000000
}

function solution6() {
  rt alice_loop out --amt 5000000 --fast
  sleep 1
  NOTTY=1 rt alice_loop monitor &
  MONITOR_PID=$!
  rt mine 1
  sleep 5
  rt mine 1
  kill $MONITOR_PID
}

function solution7() {
  rt alice_tapcli assets mint --type normal --name CHF --supply 21000000 --meta_type json --decimal_display 2
  rt alice_tapcli assets mint finalize
  rt mine 1
  sleep 1
  rt bob_tapcli u s --universe_host alice:8443
  sleep 1
  rt bob_tapcli u r
  rt alice_tapcli a l
}

function solution8() {
  BOB=$(rt bob getinfo | jq .identity_pubkey -r)
  ASSETID=$(rt alice_tapcli a l | jq -r '.assets[0].asset_genesis.asset_id')
  rt alice_litcli ln fundchannel --node_key $BOB --sat_per_vbyte 2 --asset_id $ASSETID --asset_amount 1000000
  sleep 1
  rt mine 6

  INVOICE=$(rt fabia addinvoice 50000 | jq -r '.payment_request')
  rt alice_litcli ln payinvoice --asset_id $ASSETID $INVOICE

  INVOICE2=$(rt alice_litcli ln addinvoice --asset_id $ASSETID --asset_amount 2000 | grep payment_request | cut -d'"' -f4)
  rt fabia payinvoice -f $INVOICE2 --last_hop $BOB
}

solution$1
