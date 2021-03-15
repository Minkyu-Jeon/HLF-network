#!/bin/bash

source ./setEnv.sh

createChannel(){
    rm -rf ./channel-artifacts/*
    setGlobalsForPeer0Org1
    
    peer channel create -o localhost:7050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ./artifacts/channel/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

joinChannel(){
    setGlobalsForPeer0Org1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer1Org1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer0Org2
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobalsForPeer1Org2
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
}

updateAnchorPeers(){
    setGlobalsForPeer0Org1
    peer channel update -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -c $CHANNEL_NAME \
    -f ./artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA
    
    setGlobalsForPeer0Org2
    peer channel update -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    -c $CHANNEL_NAME \
    -f ./artifacts/channel/${CORE_PEER_LOCALMSPID}anchors.tx \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile $ORDERER_CA
    
}

if [[ $# -lt 1 ]] ; then
  echo "CHANNEL_NAME is required"
  exit 0
else
  CHANNEL_NAME=$1
  shift
fi

createChannel
joinChannel
updateAnchorPeers