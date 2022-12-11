
const util = require("util");
const exec = util.promisify(require("child_process").exec);
const path = require("path");
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

async function main() {
  const circuit = await wasm_tester(path.join(__dirname, 'test_nft-ecdsa.circom'), {
    output: path.join(__dirname, '../build'),
  });
  console.log('done');
}
main().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});

// compile(path.resolve(__dirname, "test_batch_ecdsa_verify_1.circom"), {
//   wasm: true,
//   sym: true,
//   r1cs: true,
//   json: false,
//   output: path.resolve(__dirname, "../build"),
// })

async function compile (fileName, options) {    
  var flags = "--wasm ";
  if (options.sym) flags += "--sym ";
  if (options.r1cs) flags += "--r1cs ";
  if (options.json) flags += "--json ";
  if (options.output) flags += "--output " + options.output + " ";
  if (options.O === 0) flags += "--O0 "
  if (options.O === 1) flags += "--O1 "
  console.log("circom " + flags + fileName)
  b = await exec("circom " + flags + fileName);
  assert(b.stderr == "",
  "circom compiler error \n" + b.stderr);
}