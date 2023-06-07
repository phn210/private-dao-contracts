export const FUNDED: {[key: string]: {[key: string]: any[]}} = {
    '0x68Deab74A4f047C893E3b1A538386fE486604984': {
        '0xCcF5f51D2D6ce305d82f7bB47b08601F60613e29': [
            { amount: 10000000000000000n, fundingVector: [ 1, 0, 0 ] }
        ],
        '0x6A426D63AC640AFb5653b3ef06Ca73ed971D2f65': [
            { amount: 10000000000000000n, fundingVector: [ 1, 0, 0 ] }
        ],
        '0x2D864e04C09A83803B9f58ad5dd5659D0fF664e1': [
            { amount: 10000000000000000n, fundingVector: [ 0, 1, 0 ] }
        ],
        '0x0E80c0aB999228caB1f77b8714dB10d22C8D9eC8': [
            { amount: 10000000000000000n, fundingVector: [ 0, 1, 0 ] }
        ],
        '0x1AD841EA7A95C2Fd3BBA0812E538E9061A9F743b': [
            { amount: 10000000000000000n, fundingVector: [ 0, 0, 1 ] }
        ]
    }
}

export function getFundedValue(fundManager: string, investor: string): any[] {
    return FUNDED[fundManager][investor] || [];
}