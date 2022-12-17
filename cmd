./build/test_nft-ecdsa-8/test_nft-ecdsa-8_cpp/test_nft-ecdsa-8 ./test/inputs/mint8-0.json ./build/test_nft-ecdsa-8/mint8-0.wtns

/home/ec2-user/rapidsnark/build/prover ./build/test_nft-ecdsa-8/test_nft-ecdsa-8.zkey ./build/test_nft-ecdsa-8/mint8-0.wtns ./build/test_nft-ecdsa-8/mint8-0.proof ./build/test_nft-ecdsa-8/mint8-0.public.json

npx snarkjs zkey export soliditycalldata ./build/test_nft-ecdsa-8/mint8-0.public.json ./build/test_nft-ecdsa-8/mint8-0.proof
