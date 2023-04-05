#!/bin/bash
# KEY= WASM_PATH= INIT_MSG='{}' LABEL= ADMIN= sh deploy.sh
set -e

GAS="--gas-prices 0.25ukuji --gas auto --gas-adjustment 1.5 -y -b block"

# Upload Pair Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_pair.wasm --from admin-testnet -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 3
PAIR_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Pair code id: ${PAIR_CODE_ID}"
# PAIR_CODE_ID=31

# Upload Token Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_token.wasm --from admin-testnet -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 3
TOKEN_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Token code id: ${TOKEN_CODE_ID}"
# TOKEN_CODE_ID=32

# Upload Factory Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_factory.wasm --from admin-testnet -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 3
FACTORY_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Factory code id: ${FACTORY_CODE_ID}"
# FACTORY_CODE_ID=33

# Upload Router Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_router.wasm --from admin-testnet -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 3
ROUTER_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Router code id: ${ROUTER_CODE_ID}"
# ROUTER_CODE_ID=34

# Instantiate Contract
# CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo $CODE_ID
INIT_MSG="'{\"pair_code_id\": ${PAIR_CODE_ID}, \"token_code_id\": ${TOKEN_CODE_ID}}'"
echo "Init MSG: ${INIT_MSG}"
CODE_ID=33
MSG="kujirad tx wasm instantiate ${CODE_ID} ${INIT_MSG} --label 'Factory Contract' ${GAS} --broadcast-mode sync --output json -y --admin ${ADMIN} --from ${KEY}"
echo $MSG
TX_INIT=$(eval $MSG | jq -r '.txhash' && echo)
# TX_INIT=$($MSG | jq -r '.txhash') && echo $TX_INIT
sleep 3
ADDR=$(kujirad query tx $TX_INIT --output json | jq -r '.logs[0].events[0].attributes[0].value') && echo "Contract Address: $ADDR"