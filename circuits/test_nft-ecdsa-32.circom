pragma circom 2.0.5;

include "./nft-ecdsa.circom";

component main {public [addressList]} = MintNFT(32);
