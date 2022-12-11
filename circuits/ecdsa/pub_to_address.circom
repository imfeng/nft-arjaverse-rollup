pragma circom 2.0.2;

include "./zk-identity/eth.circom";
include "./ecdsa.circom";

template PubKeyToAddr(n, k) {
    signal input pubkey0[k];
    signal input pubkey1[k];
    signal output addr;

    component flattenPub = FlattenPubkey(n, k);
    for (var i = 0; i < k; i++) {
        flattenPub.chunkedPubkey[0][i] <== pubkey0[i];
        flattenPub.chunkedPubkey[1][i] <== pubkey1[i];
    }

    component pubToAddr = PubkeyToAddress();
    for (var i = 0; i < 512; i++) {
        pubToAddr.pubkeyBits[i] <== flattenPub.pubkeyBits[i];
    }

    addr <== pubToAddr.address;
}