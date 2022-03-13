#!/bin/bash

PHASE1=../../circuits/pot16_final.ptau
BUILD_DIR=../../build/verify_branch
CIRCUIT_NAME=verify_branch

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

echo '****COMPILING CIRCUIT****'
start=`date +%s`
set -x
circom "$CIRCUIT_NAME".circom --r1cs --wasm --sym --c --wat --output "$BUILD_DIR"
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"
echo

echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
start=`date +%s`
set -x
node "$BUILD_DIR"/"$CIRCUIT_NAME"_js/generate_witness.js "$BUILD_DIR"/"$CIRCUIT_NAME"_js/"$CIRCUIT_NAME".wasm input_"$CIRCUIT_NAME".json "$BUILD_DIR"/witness.wtns
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"
echo

echo "****STARTING ZKEY SETUP****"
start=`date +%s`
set -x
snarkjs groth16 setup "$BUILD_DIR"/"$CIRCUIT_NAME".r1cs "$PHASE1" "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"
echo

echo "****GENERATING FINAL ZKEY****"
start=`date +%s`
set -x
snarkjs zkey beacon "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey "$BUILD_DIR"/"$CIRCUIT_NAME".zkey 0102030405060708090a0b0c0d0e0f101112231415161718221a1b1c1d1e1f 10 -n="Final Beacon phase2"
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"
echo

echo "****VERIFYING FINAL ZKEY****"
start=`date +%s`
set -x
snarkjs zkey verify "$BUILD_DIR"/"$CIRCUIT_NAME".r1cs "$PHASE1" "$BUILD_DIR"/"$CIRCUIT_NAME".zkey
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"
echo

echo "** Exporting vkey"
start=`date +%s`
set -x
snarkjs zkey export verificationkey "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/vkey.json
end=`date +%s`
{ set +x; } 2>/dev/null
echo "DONE ($((end-start))s)"
echo

echo "****GENERATING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
set -x
snarkjs groth16 prove "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/witness.wtns "$BUILD_DIR"/proof.json "$BUILD_DIR"/public.json
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"
echo

echo "****VERIFYING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
set -x
snarkjs groth16 verify "$BUILD_DIR"/vkey.json "$BUILD_DIR"/public.json "$BUILD_DIR"/proof.json
end=`date +%s`
{ set +x; } 2>/dev/null
echo "DONE ($((end-start))s)"
echo