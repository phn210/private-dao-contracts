import {
    Element,
    MerkleTree,
    PartialMerkleTree,
    ProofPath,
} from "fixed-merkle-tree";
import Poseidon from "./poseideon-hash";
import MiMC from "./mimc-hash";

namespace Tree {
    export function getPoseidonHashTree(levels: number): MerkleTree {
        const tree: MerkleTree = new MerkleTree(levels, [], {
            hashFunction: Poseidon.hashLeftRight,
            zeroElement:
                "1117582952394327218264374806630104116016694857615943107127336590235748983513",
        });
        return tree;
    }

    export function getMiMCHashTree(levels: number): MerkleTree {
        const tree: MerkleTree = new MerkleTree(levels, [], {
            hashFunction: MiMC.hashLeftRight,
            zeroElement: MiMC.hashLeftRight(0, 0),
        });
        return tree;
    }
    export function getDefaultTree(): MerkleTree {
        return new MerkleTree(12);
    }
}

export { Tree };
