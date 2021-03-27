#!/bin/bash

. utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/artifacts/channel/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/artifacts/channel/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/artifacts/channel/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/artifacts/channel/config/

setGlobalsOrdererOrg1(){
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp
  export TLS_ROOT_CA=${PWD}/artifacts/channel/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
  export ORDERER_CONTAINER=localhost:7050
}

setGlobalsOrderer2Org1(){
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/msp
  export TLS_ROOT_CA=${PWD}/artifacts/channel/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt
  export ORDERER_CONTAINER=localhost:7050
}

setGlobalsForPeer0Org1(){
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1Org1(){
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:8051
}

setGlobalsForPeer0Org2(){
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051
}

setGlobalsForPeer1Org2(){
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/artifacts/channel/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:10051
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

setGlobals() {
  ORG=$1
  if [[ $ORG -eq 1 ]]; then
    setGlobalsForPeer0Org1
  elif [[ $ORG -eq 2 ]]; then
    setGlobalsForPeer0Org2
  fi
}