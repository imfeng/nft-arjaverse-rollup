include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "./ecdsa/batch_ecdsa.circom";
include "./ecdsa/pub_to_address.circom";

function AnswerMsgHash(k){
  // Mint Arjaverse NFT, Answer:3
  // 0xf72003f94b4bffde4528cc8e8c5213a3c34ea6c167f1ad7b0a1bc64b45db5b94
  // 728393791347317652n,
  //   14073369235182169467n,
  //   4983457900297065379n,
  //   17807237295867953118n
  if(k==0) {
    return 728393791347317652;
  } else if(k==1) {
    return 14073369235182169467;
  } else if(k==2) {
    return 4983457900297065379;
  } else if(k==3) {
    return 17807237295867953118;
  } else {
    return 0;
  }
}

template CompareChunkFieldIsAllEqual(k) {
  assert(k >= 2);
  assert(k <= 100);
  signal input a[4];
  signal input b[4];
  signal output result;

  component isPairEqual[4];
  for (var i=0; i < k; i++) {
    isPairEqual[i] = IsEqual();
    isPairEqual[i].in[0] <== a[i];
    isPairEqual[i].in[1] <== b[i];
  }

  component isAllEqualAnd = MultiAND(k);
  for (var i=0; i < k; i++) {
    isAllEqualAnd.in[i] <== isPairEqual[i].out;
  }

  result <== isAllEqualAnd.out;
}

template MintNFT(batchSize) { // n = 64, k = 4
  signal input addressList[batchSize]; // public
  signal input score[batchSize];

  signal input r[batchSize][4];
  signal input rprime[batchSize][4];
  signal input s[batchSize][4];
  signal input msghash[batchSize][4];
  signal input pubkey[batchSize][2][4];

  signal output result[batchSize];

  component batchEcdsaVerify = BatchECDSAVerifyNoPubkeyCheck(64, 4, batchSize);
  component isMsgHashCorrect[batchSize];
  component pub2Addr[batchSize]; // PubKeyToAddr
  component isAddrCorrect[batchSize];

  for (var i=0; i < batchSize; i++) {
    isMsgHashCorrect[i] = CompareChunkFieldIsAllEqual(4);
    pub2Addr[i] = PubKeyToAddr(64, 4);

    for (var j=0; j < 4; j++) {
      isMsgHashCorrect[i].a[j] <== msghash[i][j]; // request MsgHash
      isMsgHashCorrect[i].b[j] <== AnswerMsgHash(j); // answer MsgHash
      // result[i].out <== isMsgHashCorrect[i].result;

      pub2Addr[i].pubkey0[j] <== pubkey[i][0][j];
      pub2Addr[i].pubkey1[j] <== pubkey[i][1][j];
      // isAddrCorrect[i].in[0] <== pub2Addr[i].addr;
      // isAddrCorrect[i].in[1] <== addressList[i];

      batchEcdsaVerify.r[i][j] <== r[i][j];
      batchEcdsaVerify.rprime[i][j] <== rprime[i][j];
      batchEcdsaVerify.s[i][j] <== s[i][j];
      batchEcdsaVerify.msghash[i][j] <== msghash[i][j];
      batchEcdsaVerify.pubkey[i][0][j] <== pubkey[i][0][j];
      batchEcdsaVerify.pubkey[i][1][j] <== pubkey[i][1][j];
    }
  }
  batchEcdsaVerify.result === 1;


  for (var i=0; i < batchSize; i++) {
    isAddrCorrect[i] = IsEqual();
    isAddrCorrect[i].in[0] <== pub2Addr[i].addr;
    isAddrCorrect[i].in[1] <== addressList[i];
    result[i] <== isMsgHashCorrect[i].result * isAddrCorrect[i].out;
  }

}
