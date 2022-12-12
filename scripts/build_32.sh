#!/bin/bash

PHASE1=/home/ec2-user/zk-circom/ptau/final_28.ptau
BUILD_DIR=./build/test_nft-ecdsa-32
SRC_DIR=./circuits/
CIRCUIT_NAME=test_nft-ecdsa-32
INPUT_FILE=./test/inputs/mint32-0.json
RAPID_SNARK_PATH=/home/ec2-user/rapidsnark/build/prover
export NODE_OPTIONS="--max-old-space-size=1762144"

if [ -f "$PHASE1" ]; then
    echo "Found Phase 1 ptau file"
else
    echo "No Phase 1 ptau file found. Exiting..."
    exit 1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "No build directory found. Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

# echo "****COMPILING CIRCUIT****"
# start=`date +%s`
# set -x
# circom "$SRC_DIR"/"$CIRCUIT_NAME".circom --r1cs --wasm --sym --c --wat --output "$BUILD_DIR"
# { set +x; } 2>/dev/null
# end=`date +%s`
# echo "DONE ($((end-start))s)"

# echo "****GENERATING ZKEY 0****"
# start=`date +%s`
# npx snarkjs groth16 setup "$BUILD_DIR"/"$CIRCUIT_NAME".r1cs "$PHASE1" "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey
# end=`date +%s`
# echo "DONE ($((end-start))s)"

# echo "****CONTRIBUTE TO THE PHASE 2 CEREMONY****"
# start=`date +%s`
# echo "test" | npx snarkjs zkey contribute "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey "$BUILD_DIR"/"$CIRCUIT_NAME"_1.zkey --name="1st Contributor Name"
# end=`date +%s`
# echo "DONE ($((end-start))s)"

# echo "****GENERATING FINAL ZKEY****"
# start=`date +%s`
# npx snarkjs zkey beacon "$BUILD_DIR"/"$CIRCUIT_NAME"_1.zkey "$BUILD_DIR"/"$CIRCUIT_NAME".zkey 0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f 10 -n="Final Beacon phase2"
# end=`date +%s`
# echo "DONE ($((end-start))s)"

# echo "** Exporting vkey"
# start=`date +%s`
# npx snarkjs zkey export verificationkey "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/vkey.json
# end=`date +%s`
# echo "DONE ($((end-start))s)"

echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
start=`date +%s`
# node "$BUILD_DIR"/"$CIRCUIT_NAME"_js/generate_witness.js "$BUILD_DIR"/"$CIRCUIT_NAME"_js/"$CIRCUIT_NAME".wasm "$INPUT_FILE" "$BUILD_DIR"/witness.wtns
"$BUILD_DIR"/"$CIRCUIT_NAME"_cpp/"$CIRCUIT_NAME" "$INPUT_FILE" "$BUILD_DIR"/witness.wtns
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "****GENERATING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
# npx snarkjs groth16 prove "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
"$RAPID_SNARK_PATH" prove "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "****VERIFYING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
npx snarkjs groth16 verify "$BUILD_DIR"/vkey.json "$BUILD_DIR"/public.json "$BUILD_DIR"/proof.json
end=`date +%s`
echo "DONE ($((end-start))s)"


snarkjs zkey export solidityverifier "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/"$CIRCUIT_NAME"-verifier.sol
snarkjs zkey export soliditycalldata "$BUILD_DIR"/public.json ${proofPath} "$BUILD_DIR"/proof.json >> "$BUILD_DIR"/"$CIRCUIT_NAME"-calldata.txt