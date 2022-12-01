include "../node_modules/circomlib/circuits/comparators.circom";

template MintNFT(batchSize) {
  signal input addressList[batchSize]; // public

  signal input score[batchSize];
  signal input ecdsaSig[batchSize];
  signal input PXs[batchSize];
  signal input PYs[batchSize];
  signal input BXs[batchSize];
  signal input BYs[batchSize];
  
  component isZero[batchSize];
  for (var i = 0; i < batchSize; i++) {
    isZero[i] = IsZero();
    isZero[i].in <== score[i];
    isZero[i].out === 1;
  }

  for (var i = 0; i < batchSize; i++) {
    PXs[i] === BXs[i];
    PYs[i] === BYs[i];
  }

}


component main {public [addressList]} = MintNFT(16); 