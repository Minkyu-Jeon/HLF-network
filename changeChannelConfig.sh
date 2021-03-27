#!/bin/bash

source setEnv.sh
source configUpdate.sh

mkdir -p ./tmp

createPeerUpdate() {
  infoln "Fetch channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ./tmp/${CORE_PEER_LOCALMSPID}config.json

  BATCH_SIZE_VERSION=`jq -r '.channel_group.groups.Orderer.values.BatchSize.version' ./tmp/${CORE_PEER_LOCALMSPID}config.json`
  NEXT_BATCH_SIZE_VERSION=$((BATCH_SIZE_VERSION + 1))
  BATCH_SIZE_VALUE_ABSOLUTE_MAX_BYTES=`jq -r '.channel_group.groups.Orderer.values.BatchSize.value.absolute_max_bytes' ./tmp/${CORE_PEER_LOCALMSPID}config.json`
  BATCH_SIZE_VALUE_MAX_MESSAGE_COUNT=`jq -r '.channel_group.groups.Orderer.values.BatchSize.value.max_message_count' ./tmp/${CORE_PEER_LOCALMSPID}config.json`
  BATCH_SIZE_VALUE_PREFERRED_MAX_BYTES=`jq -r '.channel_group.groups.Orderer.values.BatchSize.value.preferred_max_bytes' ./tmp/${CORE_PEER_LOCALMSPID}config.json`
  BATCH_SIZE_VALUE_ABSOLUTE_MAX_BYTES=${ABSOLUTE_MAX_BYTES:-$BATCH_SIZE_VALUE_ABSOLUTE_MAX_BYTES}
  BATCH_SIZE_VALUE_MAX_MESSAGE_COUNT=${MAX_MESSAGE_COUNT:-$BATCH_SIZE_VALUE_MAX_MESSAGE_COUNT}
  BATCH_SIZE_VALUE_PREFERRED_MAX_BYTES=${PREFERRED_MAX_BYTES:-$BATCH_SIZE_VALUE_PREFERRED_MAX_BYTES}

  BATCH_TIMEOUT_VERSION=`jq -r '.channel_group.groups.Orderer.values.BatchTimeout.version' ./tmp/${CORE_PEER_LOCALMSPID}config.json`
  NEXT_BATCH_TIMEOUT_VERSION=$((BATCH_TIMEOUT_VERSION + 1))
  BATCH_TIMEOUT_VALUE_TIMEOUT=`jq -r '.channel_group.groups.Orderer.values.BatchTimeout.value.timeout' ./tmp/${CORE_PEER_LOCALMSPID}config.json`
  BATCH_TIMEOUT_VALUE_TIMEOUT=${TIMEOUT:-$BATCH_TIMEOUT_VALUE_TIMEOUT}

  infoln "Generating Org${ORG} on channel $CHANNEL_NAME"
  BATCH_SIZE_CONFIG="{ \"mod_policy\": \"Admins\", \"value\": { \"absolute_max_bytes\": ${BATCH_SIZE_VALUE_ABSOLUTE_MAX_BYTES}, \"max_message_count\": ${BATCH_SIZE_VALUE_MAX_MESSAGE_COUNT}, \"preferred_max_bytes\": ${BATCH_SIZE_VALUE_PREFERRED_MAX_BYTES} }, \"version\": \"${NEXT_BATCH_SIZE_VERSION}\" }"
  BATCH_TIMEOUT_CONFIG="{\"mod_policy\":\"Admins\", \"value\": { \"timeout\": \"${BATCH_TIMEOUT_VALUE_TIMEOUT}\" }, \"version\": \"${NEXT_BATCH_TIMEOUT_VERSION}\" }"
  infoln "BATCH_SIZE_CONFIG: ${BATCH_SIZE_CONFIG}"
  infoln "BATCH_TIMEOUT_CONFIG: ${BATCH_TIMEOUT_CONFIG}"
  jq --argjson a "${BATCH_SIZE_CONFIG}" --argjson b "${BATCH_TIMEOUT_CONFIG}" '.channel_group.groups.Orderer.values.BatchSize = $a | .channel_group.groups.Orderer.values.BatchTimeout = $b' ./tmp/${CORE_PEER_LOCALMSPID}config.json > ./tmp/${CORE_PEER_LOCALMSPID}modified_config.json

  createConfigUpdate ${CHANNEL_NAME} ./tmp/${CORE_PEER_LOCALMSPID}config.json ./tmp/${CORE_PEER_LOCALMSPID}modified_config.json ./artifacts/channel/${CORE_PEER_LOCALMSPID}${TX_FILENAME}.tx
}

updateSystemChannel() {
  peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f artifacts/channel/Org1MSP${TX_FILENAME}.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}


ORG=$1
CHANNEL_NAME=$2
TX_FILENAME=$3

ABSOLUTE_MAX_BYTES=$4
MAX_MESSAGE_COUNT=$5
PREFERRED_MAX_BYTES=$6
TIMEOUT=$7


setGlobalsForPeer0Org1

createPeerUpdate

setGlobalsOrdererOrg1

signConfigtxAsPeerOrg 1 ./tmp/Org1MSP${TX_FILENAME}.tx

updateSystemChannel

rm -rf ./tmp