import { expect } from "chai"
import { MerkleTree } from "zkp-merkle-airdrop-lib";
import { generateMerkleTreeAndKeys, saveMerkleTreeAndSource } from "../utils/TestUtils";

describe("MerkleTree", function () {
    this.timeout(1000 * 1000);
    it("can be constructed and destructed", () => {
        let mtk = generateMerkleTreeAndKeys(2**6);
        console.log('?')
        saveMerkleTreeAndSource(mtk);
        let ss1 = mtk.merkleTree.getStorageString();
        let mt2 = MerkleTree.createFromStorageString(ss1);
        let ss2 = mt2.getStorageString();

        expect(ss1).to.be.eq(ss2);
    })
})