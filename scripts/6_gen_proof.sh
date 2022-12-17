#!/bin/bash

INPUT_NAME=mint8-0
BUILD_DIR=./build/test_nft-ecdsa-8
CIRCUIT_NAME=test_nft-ecdsa-8
RAPID_SNARK_PATH=/home/ec2-user/rapidsnark/build/prover


echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
start=`date +%s`
"$BUILD_DIR"/"$CIRCUIT_NAME"_cpp/"$CIRCUIT_NAME" ./test/inputs/"$INPUT_NAME".json "$BUILD_DIR"/"$INPUT_NAME".wtns
"$RAPID_SNARK_PATH" "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/"$INPUT_NAME".wtns "$BUILD_DIR"/"$INPUT_NAME".proof "$BUILD_DIR"/"$INPUT_NAME".public.json
end=`date +%s`
echo "DONE ($((end-start))s)"
echo ""

npx snarkjs zkey export soliditycalldata "$BUILD_DIR"/"$INPUT_NAME".public.json "$BUILD_DIR"/"$INPUT_NAME".proof
