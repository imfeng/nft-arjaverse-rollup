pragma circom 2.0.2;

include "./ecdsa/ecdsa.circom";

component main {public [privkey]} = ECDSAPrivToPub(64, 4);
