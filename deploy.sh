#!/bin/bash
# KEY= DENOM= sh deploy.sh
set -e

GAS="--gas-prices 0.25ukuji --gas auto --gas-adjustment 1.5 -y -b block"

# Get the Admin Wallet Address from the Key Name
ADMIN=$(kujirad keys show $KEY -a) && echo "Admin: $ADMIN"

# Upload Pair Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_pair.wasm --from $KEY -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 2
PAIR_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Pair code id: ${PAIR_CODE_ID}"

# Upload Token Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_token.wasm --from $KEY -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 2
TOKEN_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Token code id: ${TOKEN_CODE_ID}"

# Upload Factory Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_factory.wasm --from $KEY -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 2
FACTORY_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Factory code id: ${FACTORY_CODE_ID}"

# Upload Router Contract
CONTRACT=$(kujirad tx wasm store artifacts/terraswap_router.wasm --from $KEY -y --broadcast-mode sync --output json $GAS | jq -r '.txhash') && echo $CONTRACT
sleep 2
ROUTER_CODE_ID=$(kujirad query tx $CONTRACT --output json | jq -r '.logs[0].events[-1].attributes[-1].value') && echo "Router code id: ${ROUTER_CODE_ID}"

# Instantiate Factory Contract
INIT_MSG="'{\"pair_code_id\": ${PAIR_CODE_ID}, \"token_code_id\": ${TOKEN_CODE_ID}}'"
MSG="kujirad tx wasm instantiate ${FACTORY_CODE_ID} ${INIT_MSG} --label 'Factory Contract' ${GAS} --broadcast-mode sync --output json -y --admin ${ADMIN} --from ${KEY}"
TX_INIT=$(eval $MSG | jq -r '.txhash' && echo)
sleep 3
ADDR=$(kujirad query tx $TX_INIT --output json | jq -r '.logs[0].events[0].attributes[0].value') && echo "FinSwap Factory Contract Address: $ADDR"

# Create New Native Denom and mint 1 Million to Self
DENOM_RESULT=$(kujirad tx denom create-denom $DENOM $GAS --from $KEY --output json | jq -r '.txhash') && echo "Denom: $DENOM_RESULT"
DENOM="factory/${ADMIN}/${DENOM}"
sleep 1
MINT_MSG="kujirad tx denom mint "1000000000000${DENOM}" $ADMIN $GAS --from $KEY --output json"
MINT=$(eval $MINT_MSG | jq -r '.txhash') && echo "Mint: $MINT"
sleep 1
# Send 1 kuji to the factory contract
SEND_MSG="kujirad tx bank send $ADMIN $ADDR 1000000ukuji $GAS --from $KEY --output json"
SEND_RESULT=$(eval $SEND_MSG | jq -r '.txhash') && echo "Send: $SEND_RESULT"
sleep 1
# Send 1 token of the denom to the factory contract
SEND_MSG="kujirad tx bank send $ADMIN $ADDR 1000000${DENOM} $GAS --from $KEY --output json"
SEND_RESULT=$(eval $SEND_MSG | jq -r '.txhash') && echo "Send: $SEND_RESULT"
# Register the denom with the factory contract
ADD_DECIMALS_MSG="'{\"add_native_token_decimals\":{\"denom\": \"${DENOM}\", \"decimals\": 6}}'"
MSG="kujirad tx wasm execute $ADDR $ADD_DECIMALS_MSG $GAS --from $KEY --output json"
RESULT=$(eval $MSG | jq -r '.txhash') && echo "Add Decimals for ${DENOM}: $RESULT"
# Register ukuji denom with the factory contract
ADD_DECIMALS_MSG="'{\"add_native_token_decimals\":{\"denom\": \"ukuji\", \"decimals\": 6}}'"
MSG="kujirad tx wasm execute $ADDR $ADD_DECIMALS_MSG $GAS --from $KEY --output json"
RESULT=$(eval $MSG | jq -r '.txhash') && echo "Add Decimals for ukuji: $RESULT"
sleep 1
# Create Pair  
ASSET_INFOS="'{\"create_pair\":{\"asset_infos\":[{\"native_token\": {\"denom\": \"ukuji\"}}, {\"native_token\": {\"denom\": \"${DENOM}\"}}]}}'"
CREATE_PAIR_MSG="kujirad tx wasm execute ${ADDR} ${ASSET_INFOS} $GAS --from $KEY --output json"
echo "Create Pair: $CREATE_PAIR_MSG"
CREATE_PAIR_RESULT=$(eval $CREATE_PAIR_MSG | jq -r '.txhash') && echo "Create Pair: $CREATE_PAIR_RESULT"
sleep 1
PAIR_ADDR=$(kujirad query tx $CREATE_PAIR_RESULT --output json | jq -r '.logs[0].events[] | select(.type == "wasm") | .attributes[] | select(.key == "pair_contract_addr") | .value') && echo "Pair Address: $PAIR_ADDR"
# Provide Liquidity to Pair
PROVIDE_LIQ_MSG="'{\"provide_liquidity\":{\"assets\":[{\"info\":{\"native_token\":{\"denom\":\"ukuji\"}},\"amount\":\"10000000\"},{\"info\":{\"native_token\":{\"denom\":\"${DENOM}\"}},\"amount\":\"500000000000\"}]}}'"
MSG="kujirad tx wasm execute $PAIR_ADDR $PROVIDE_LIQ_MSG $GAS --from $KEY --output json --amount 10000000ukuji,500000000000${DENOM}"
PROVIDE_LIQ_RESULT=$(eval $MSG | jq -r '.txhash') && echo "Provide Liquidity: $PROVIDE_LIQ_RESULT"