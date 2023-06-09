export const FUNDED: {[key: string]: {[key: string]: any[]}} = {
    '0xb4Dde6Dba767A281ef15bc4c64E8607ceC25420D': {
        '0xccf5f51d2d6ce305d82f7bb47b08601f60613e29': [
            {
                amount: 10000000000000000n,
                fundingVector: [ 1, 0, 0 ],
                commitment: 8729045990458720092177554556566367530966918467096221251221194014375854871291n
            }
        ],
        '0x6a426d63ac640afb5653b3ef06ca73ed971d2f65': [
            {
                amount: 10000000000000000n,
                fundingVector: [ 1, 0, 0 ],
                commitment: 19408636529744528362576073263845617040871301005450289790834574920757484677787n
            }
        ],
        '0x2d864e04c09a83803b9f58ad5dd5659d0ff664e1': [
            {
                amount: 10000000000000000n,
                fundingVector: [ 0, 1, 0 ],
                commitment: 12191534133526656252298437085850784513855780524522070282054045591756140055616n
            }
        ],
        '0x0e80c0ab999228cab1f77b8714db10d22c8d9ec8': [
            {
                amount: 10000000000000000n,
                fundingVector: [ 0, 1, 0 ],
                commitment: 20005001368570141723988780948214417802738230393163470930594350534677188738531n
            }
        ],
        '0x1ad841ea7a95c2fd3bba0812e538e9061a9f743b': [
            {
                amount: 10000000000000000n,
                fundingVector: [ 0, 0, 1 ],
                commitment: 18479541686287050468871183552712480941854540799758827866146072778929985966886n
            }
        ]
    }
}

export function getFundedValue(fundManager: string, investor: string): any[] {
    return FUNDED[fundManager][investor] || [];
}