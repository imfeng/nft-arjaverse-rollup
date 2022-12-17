import path = require('path');

import { expect, assert } from 'chai';
import { getPublicKey, sign, Point, CURVE, recoverPublicKey } from '@noble/secp256k1';
import _ from 'lodash';
import { utils } from 'ethers';
import { publicKeyConvert } from 'secp256k1';
import fs from 'fs';
const batchSize = 8;

const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

const _0n = BigInt(0);
const _1n = BigInt(1);
const _2n = BigInt(2);
const _3n = BigInt(3);
const _8n = BigInt(8);

// Calculates a modulo b
function mod(a: bigint, b: bigint = CURVE.P): bigint {
  const result = a % b;
  return result >= _0n ? result : b + result;
}

// Inverses number over modulo
function invert(number: bigint, modulo: bigint = CURVE.P): bigint {
  if (number === _0n || modulo <= _0n) {
    throw new Error(`invert: expected positive integers, got n=${number} mod=${modulo}`);
  }
  // Eucledian GCD https://brilliant.org/wiki/extended-euclidean-algorithm/
  let a = mod(number, modulo);
  let b = modulo;
  // prettier-ignore
  let x = _0n, y = _1n, u = _1n, v = _0n;
  while (a !== _0n) {
    const q = b / a;
    const r = b % a;
    const m = x - u * q;
    const n = y - v * q;
    // prettier-ignore
    b = a, a = r, x = u, y = v, u = m, v = n;
  }
  const gcd = b;
  if (gcd !== _1n) throw new Error('invert: does not exist');
  return mod(x, modulo);
}

function bigint_to_array(n: number, k: number, x: bigint) {
  let mod: bigint = 1n;
  for (var idx = 0; idx < n; idx++) {
    mod = mod * 2n;
  }

  let ret: bigint[] = [];
  var x_temp: bigint = x;
  for (var idx = 0; idx < k; idx++) {
    ret.push(x_temp % mod);
    x_temp = x_temp / mod;
  }
  return ret;
}

// bigendian
function bigint_to_Uint8Array(x: bigint, length: number = 32) {
  var ret: Uint8Array = new Uint8Array(length);
  for (var idx = length - 1; idx >= 0; idx--) {
    ret[idx] = Number(x % 256n);
    x = x / 256n;
  }
  return ret;
}

// bigendian
function Uint8Array_to_bigint(x: Uint8Array) {
  var ret: bigint = 0n;
  for (var idx = 0; idx < x.length; idx++) {
    ret = ret * 256n;
    ret = ret + BigInt(x[idx]);
  }
  return ret;
}

describe('ECDSABatchVerifyNoPubkeyCheck', function () {
  this.timeout(1000 * 1000);

  // privkey, msghash, pub0, pub1
  var test_cases: Array<[bigint, bigint, bigint, bigint]> = [];
  var privkeys: Array<bigint> = [
    BigInt("0x8ba10a62340514aa5eb89abe4a69364a5c3e8f5cdb10cf003b8d0a98649b480e"),
    // 37706893564732085918706190942542566344879680306879183356840008504374628845468n,
    // 90388020393783788847120091912026443124559466591761394939671630294477859800601n,
    // 110977009687373213104962226057480551605828725303063265716157300460694423838923n,
  ];
  for (var idx = 0; idx < privkeys.length; idx++) {
    var pubkey: Point = Point.fromPrivateKey(privkeys[idx]);
    var msghash_bigint: bigint = BigInt("0xf72003f94b4bffde4528cc8e8c5213a3c34ea6c167f1ad7b0a1bc64b45db5b94");
    test_cases.push([privkeys[idx], msghash_bigint, pubkey.x, pubkey.y]);
  }

  var batch_test_cases = [test_cases]; // We have all 4 in a test case

  let circuit: any;
  before(async function () {
    // circuit = await wasm_tester(path.join(__dirname, '../circuits', 'test_batch_ecdsa_verify_4.circom'), {
    //   output: path.join(__dirname, '../build'),
    // });
  });
  var recoverInputs = [];

  var test_batch_ecdsa_verify = function (batch_test_case: [bigint, bigint, bigint, bigint][]) {
    var collated_batch_ = batch_test_case.map(async (test_case) => {
      let privkey = test_case[0];
      let msghash_bigint = test_case[1];
      let pub0 = test_case[2];
      let pub1 = test_case[3];
      var msghash: Uint8Array = bigint_to_Uint8Array(msghash_bigint);

      var sig: Uint8Array = await sign(msghash, bigint_to_Uint8Array(privkey), {
        canonical: true,
        der: false,
      });
      const splitSignatureValue = utils.splitSignature(sig);
      console.log({
        tt: 'TEST',
        sigBig: Uint8Array_to_bigint(sig).toString(16),
        sigUint8: sig,
        sigGG: bigint_to_Uint8Array(Uint8Array_to_bigint(sig), 64),
        splitSignatureValue,
      })
      const pp = Point.fromSignature(msghash, sig, splitSignatureValue.recoveryParam);
      const publicKey = utils.recoverPublicKey(msghash, sig);
      const address = utils.recoverAddress(msghash, sig);
      const pubX = Uint8Array_to_bigint(Buffer.from(publicKey).slice(0, 32)).toString(16);
      const pubY = Uint8Array_to_bigint(Buffer.from(publicKey).slice(32, 64)).toString(16);

      // const recoverKey = recoverPublicKey(`${}`, sig);
      var r: Uint8Array = sig.slice(0, 32);
      var s: Uint8Array = sig.slice(32, 64);
      var v: number = sig[64];
      var r_bigint: bigint = Uint8Array_to_bigint(r);
      var s_bigint: bigint = Uint8Array_to_bigint(s);


      console.log({
        splitSignatureValue: splitSignatureValue.compact,
        r: r_bigint.toString(16),
        s: s_bigint.toString(16),
        v,
        pp: {
          x: pp.x.toString(16),
          y: pp.y.toString(16),
        },
        publicKey, address, pubX, pubY, pub0: pub0.toString(16), pub1: pub1.toString(16)
      })


      const { n } = CURVE;
      var p_1 = Point.BASE.multiply(mod(msghash_bigint * invert(s_bigint, n), n));
      var p_2 = Point.fromPrivateKey(privkey).multiply(mod(r_bigint * invert(s_bigint, n), n));
      var p_res = p_1.add(p_2);
      var rprime_bigint: bigint = p_res.y;

      var r_array: bigint[] = bigint_to_array(64, 4, r_bigint);
      var rprime_array: bigint[] = bigint_to_array(64, 4, rprime_bigint);
      var s_array: bigint[] = bigint_to_array(64, 4, s_bigint);
      var msghash_array: bigint[] = bigint_to_array(64, 4, msghash_bigint);
      var pub0_array: bigint[] = bigint_to_array(64, 4, pub0);
      var pub1_array: bigint[] = bigint_to_array(64, 4, pub1);

      return [r_array, rprime_array, s_array, msghash_array, [pub0_array, pub1_array], 
      {publicKey, address}];
    });

    var collated_batch = Promise.all(collated_batch_);

      it('testing correct sig', async function () {
        var x = await collated_batch;
        var res = 1n;
        // const mintNftInputs = {
        //   addressList: ,
        //   score,
        //   r,
        //   rprime,
        //   s,
        //   msghash,
        //   pubkey
        // }
        // const inputs = {
        //   r: _.map(x, (e: any) => e[0]),
        //   rprime: _.map(x, (e: any) => e[1]),
        //   s: _.map(x, (e: any) => e[2]),
        //   msghash: _.map(x, (e: any) => e[3]),
        //   pubkey: _.map(x, (e: any) => e[4]),
        //   recover: _.map(x, (e: any) => e[5]),
        // };
        // let witness = await circuit.calculateWitness();
        // expect(witness[1]).to.equal(res);
        // await circuit.checkConstraints(witness);
        // console.log({
        //   mintNftInputs
        // })
      });

      // it('testing incorrect sig', async function () {
      //   var x = await collated_batch;
      //   var res = 0n;
      //   let witness = await circuit.calculateWitness({
      //     r: _.map(x, (e: any) => e[0]),
      //     rprime: _.map(x, (e: any) => e[1]),
      //     s: _.map(x, (e: any) => e[2]),
      //     msghash: _.map(x, (e: any) => e[3].map((x: any) => x + 1n)),
      //     pubkey: _.map(x, (e: any) => e[4]),
      //   });
      //   expect(witness[1]).to.equal(res);
      //   await circuit.checkConstraints(witness);
      // });
  };
  batch_test_cases.forEach(test_batch_ecdsa_verify);
});


/**
 * ECDSA public key recovery from signature
 * @param {Buffer} msgHash
 * @param {Number} v
 * @param {Buffer} r
 * @param {Buffer} s
 * @return {Buffer} publicKey
 */
function recover(msgHash: Uint8Array, signature: Uint8Array, v: number) {
  // const v = Number(signature.slice(0, 2));
  // if (recovery !== 0 && recovery !== 1) {
  //   throw new Error('Invalid signature v value')
  // }
  // const senderPubKey = recoverPublicKey(msgHash, signature, v);
  const publicKey = utils.recoverPublicKey(msgHash, signature);
  const address = publicKeyToAddress(publicKey);
  console.log({
    publicKey,
    address,
  })
  return {senderPubKey: 0, address};
}


function publicKeyToAddress (publicKey: Buffer | string) {
  if (!Buffer.isBuffer(publicKey)) {
    if (typeof publicKey !== 'string') {
      throw new Error('Expected Buffer or string as argument')
    }

    publicKey = publicKey.slice(0, 2) === '0x' ? publicKey.slice(2) : publicKey
    publicKey = Buffer.from(publicKey, 'hex')
  }
  
  publicKey = Buffer.from(publicKeyConvert(publicKey, false)).slice(1)
  const hash = Buffer.from(utils.keccak256(publicKey));
  return hash.slice(-20).toString('hex');
}

function getRPrime(pp: Point, msghash_bigint: bigint, r_bigint: bigint, s_bigint: bigint, ) {
  const { n } = CURVE;
  const p_1 = Point.BASE.multiply(mod(msghash_bigint * invert(s_bigint, n), n));
  const p_2 = pp.multiply(mod(r_bigint * invert(s_bigint, n), n));
  const p_res = p_1.add(p_2);
  const rprime_bigint: bigint = p_res.y;
  return rprime_bigint;
}

function genInputs(storagePath: string, batchSize: number = 32) {
  const storageData = fs.readFileSync(storagePath, 'utf8');
  const datas = JSON.parse(storageData);
  const mintInfoList = datas.storage.mintInfo;
  for (let index = 0; (index + batchSize) < mintInfoList.length; index += batchSize) {
    const inputs = parseStorage(mintInfoList.slice(index, index + batchSize));
    if(inputs.addressList.length !== batchSize) {
      console.log('BREAK');
      break;
    }
    fs.writeFileSync(path.resolve(__dirname, `../mint${batchSize}-${index}.json`), JSON.stringify(inputs, null, 2));
  }
  console.log('DONE');

}

function parseStorage(mintInfoList: any[]) {
  
  const addressList: bigint[] = mintInfoList.map((v: any) => BigInt(v.address));
  const score: bigint[] = mintInfoList.map((v: any) => BigInt(0));

  const msghashRaw: bigint[] = mintInfoList.map((v: any) =>  BigInt(utils.hashMessage(v.message)));
  const msghash = msghashRaw.map((raw) => bigint_to_array(64, 4, raw));
  
  const sigBuffers: Buffer[] = mintInfoList.map((v: any) => Buffer.from(v.signature.slice(2), 'hex'));
  const splitSignatureValueList = sigBuffers.map(b => utils.splitSignature(b));
  const pointList: Point[] = [];

  for (let index = 0; index < msghashRaw.length; index++) {
    const _msgHash = msghashRaw[index];
    const _splitSignatureValue = splitSignatureValueList[index];
    const r_bytes = bigint_to_Uint8Array(BigInt(_splitSignatureValue.r))
    const s_bytes = bigint_to_Uint8Array(BigInt(_splitSignatureValue.s))
    const _sig = new Uint8Array([...r_bytes, ...s_bytes]);
    pointList.push(Point.fromSignature(bigint_to_Uint8Array(_msgHash), _sig, _splitSignatureValue.recoveryParam));
  }

  const r: Array<BigInt[]> = splitSignatureValueList.map((s: any) => bigint_to_array(64, 4, BigInt(s.r)));
  const s: Array<BigInt[]> = splitSignatureValueList.map((s: any) => bigint_to_array(64, 4, BigInt(s.s)));
  const rprime: Array<BigInt[]> = [];
  for (let index = 0; index < pointList.length; index++) {
    const _pp = pointList[index];
    const _msgHash = msghashRaw[index];
    const _r_bigint = BigInt(splitSignatureValueList[index].r);
    const _s_bigint = BigInt(splitSignatureValueList[index].s);
    const _rprime_bigint = getRPrime(_pp, _msgHash, _r_bigint, _s_bigint);
    rprime.push(bigint_to_array(64, 4, _rprime_bigint)); 
  }

  const pubkey: Array<[BigInt[], BigInt[]]> = pointList.map((p: Point) => [
    bigint_to_array(64, 4, p.x), bigint_to_array(64, 4, p.y)
  ]);

  return {
    addressList,
    score,
    r,
    rprime,
    s,
    msghash,
    pubkey
  }
}

genInputs(path.resolve(__dirname, '../storage.json'));
