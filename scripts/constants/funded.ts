export const FUNDED: {[key: string]: {[key: string]: any[]}} = {
    '0x119ca4dbdc5e30749b85a6edcb3a0c99444e6062': {
        '0xccf5f51d2d6ce305d82f7bb47b08601f60613e29': [
            { amount: 10000000000000000n, fundingVector: [ 1, 0, 0 ], commitment: '0x0413200c1ea35304505bbfc20d819755f6bc9071dbe651d04cc35bf0ee5659d6' }
        ],
        '0x6a426d63ac640afb5653b3ef06ca73ed971d2f65': [
            { amount: 10000000000000000n, fundingVector: [ 1, 0, 0 ], commitment: '0x2fe5786118101dcd0a2c20ac3d0178a39f820b539756a679a5e5d7054cea6083' }
        ],
        '0x2d864e04c09a83803b9f58ad5dd5659d0ff664e1': [
            { amount: 10000000000000000n, fundingVector: [ 0, 1, 0 ], commitment: '0x2dc9e4e79eec43143a4e820ad66ef4d4427de7bcf20a47598c4cbbbf76dff4f7' }
        ],
        '0x0e80c0ab999228cab1f77b8714db10d22c8d9ec8': [
            { amount: 10000000000000000n, fundingVector: [ 0, 1, 0 ], coWmmitment: '0x020d0b3023f4fa328a63c6ccadb4e78188f11dfe1a461eb97e26d8f42d4f0d53' }
        ],
        '0x1ad841ea7a95c2fd3bba0812e538e9061a9f743b': [
            { amount: 10000000000000000n, fundingVector: [ 0, 0, 1 ], commitment: '0x071f3c090b53ab4972fe2031c083c0ae2f7622b0e929087a52aaa5552eda8149' }
        ]
    }
}

export function getFundedValue(fundManager: string, investor: string): any[] {
    return FUNDED[fundManager][investor] || [];
}