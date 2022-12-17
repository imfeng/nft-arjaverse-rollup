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

function getRPrime(pp: Point, msghash_bigint: bigint, r_bigint: bigint, s_bigint: bigint, ) {
  const { n } = CURVE;
  const p_1 = Point.BASE.multiply(mod(msghash_bigint * invert(s_bigint, n), n));
  const p_2 = pp.multiply(mod(r_bigint * invert(s_bigint, n), n));
  const p_res = p_1.add(p_2);
  const rprime_bigint: bigint = p_res.y;
  return rprime_bigint;
}

function genInputs(storagePath: string, batchSize: number) {
  const storageData = fs.readFileSync(storagePath, 'utf8');
  const datas = JSON.parse(storageData);
  const mintInfoList = datas.storage.mintInfo;
  
  mintInfoList.forEach((item: any, index: number) => {
    const { address, message, signature} = item;
    const isVaild = verifyEthereumsignature(address, message, signature);
    if(!isVaild) {
      console.error('invalid signature', index , item)
    }
  });
  const validMintInfoList = mintInfoList.filter((item: any) => {
    const { address, message, signature} = item;
    const isVaild = verifyEthereumsignature(address, message, signature);
    return isVaild;
  });

  console.log({
    batchSize,
    rawLength: mintInfoList.length,
    validLength: validMintInfoList.length,
  })
  for (let index = 0; (index + batchSize) <= validMintInfoList.length; index += batchSize) {
    const inputs = parseStorage(validMintInfoList.slice(index, index + batchSize));
    if(inputs.addressList.length !== batchSize) {
      console.log('BREAK');
      break;
    }
    fs.writeFileSync(path.resolve(__dirname, `../test/inputs/mint${batchSize}-${index}.json`), JSON.stringify(inputs, null, 2));
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

function verifyEthereumsignature(address: string, message: string, signature: string) {
  const msgHash = utils.hashMessage(message);
  const splitSignatureValue = utils.splitSignature(signature);
  const recover = utils.recoverAddress(msgHash, splitSignatureValue);
  return address.toLowerCase() === recover.toLowerCase();
}

genInputs(path.resolve(__dirname, '../storage.json'), batchSize);
