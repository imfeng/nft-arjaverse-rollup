./build/test_nft-ecdsa/test_nft-ecdsa_cpp/test_nft-ecdsa ./test/inputs/mint2-0.json ./build/test_nft-ecdsa/mint2-0.wtns

./build/prove <circuit.zkey> <witness.wtns> <proof.json> <public.json>

/home/ec2-user/rapidsnark/build/prover ./build/test_nft-ecdsa/test_nft-ecdsa.zkey ./build/test_nft-ecdsa/mint2-0.wtns ./build/test_nft-ecdsa/mint2-0.proof ./build/test_nft-ecdsa/mint2-0.public.json

npx snarkjs plonk prove ./build/test_nft-ecdsa/test_nft-ecdsa.zkey ./build/test_nft-ecdsa/mint2-0.wtns ./build/test_nft-ecdsa/mint2-0.proof ./build/test_nft-ecdsa/mint2-0.public.json