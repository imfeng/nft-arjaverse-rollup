pragma circom 2.0.5;

include "./ecdsa/batch_ecdsa.circom";

component main {public [r, rprime, s, msghash, pubkey]} = BatchECDSAVerifyNoPubkeyCheck(64, 4, 4);
