export default {
    "": {
        "chainId": 11155111
    },
    "round2contributionverifier": {
        "address": "",
        "interface": [
            "function getPublicInputsLength() pure returns (uint256) @1000000",
            "function verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[]) view returns (bool) @1000000"
        ]
    },
    "fundingverifierdim3": {
        "address": "",
        "interface": [
            "function getPublicInputsLength() pure returns (uint256) @1000000",
            "function verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[]) view returns (bool) @1000000"
        ]
    },
    "votingverifierdim3": {
        "address": "",
        "interface": [
            "function getPublicInputsLength() pure returns (uint256) @1000000",
            "function verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[]) view returns (bool) @1000000"
        ]
    },
    "tallycontributionverifierdim3": {
        "address": "",
        "interface": [
            "function getPublicInputsLength() pure returns (uint256) @1000000",
            "function verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[]) view returns (bool) @1000000"
        ]
    },
    "resultverifierdim3": {
        "address": "",
        "interface": [
            "function getPublicInputsLength() pure returns (uint256) @1000000",
            "function verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[]) view returns (bool) @1000000"
        ]
    },
    "poseidonunit2": {
        "address": "",
        "interface": [
            "function poseidon(uint256[]) pure returns (uint256) @1000000"
        ]
    },
    "poseidon": {
        "address": "",
        "interface": [
            "constructor(address)",
            "function hash(uint256[2]) view returns (uint256) @1000000",
            "function poseidon2() view returns (address) @1000000"
        ]
    },
    "fundmanager": {
        "address": "",
        "interface": [
            "constructor(address[],address,uint256,tuple(uint32,address),tuple(uint64,uint64,uint64),tuple(address,address,address,address,address))",
            "event FundWithdrawed(uint256 indexed,address indexed,uint256 indexed)",
            "event Funded(uint256 indexed,address,uint256,uint256 indexed)",
            "event FundingRoundApplied(address indexed)",
            "event FundingRoundFailed(uint256 indexed)",
            "event FundingRoundFinalized(uint256 indexed)",
            "event FundingRoundLaunched(uint256 indexed,bytes32 indexed)",
            "event LeafInserted(uint256 indexed)",
            "event Refunded(uint256 indexed,address indexed,uint256 indexed)",
            "event TallyResultSubmitted(bytes32 indexed,uint256[] indexed)",
            "event TallyStarted(uint256 indexed,bytes32 indexed)",
            "function FIELD_SIZE() view returns (uint256) @1000000",
            "function ROOT_HISTORY_SIZE() view returns (uint32) @1000000",
            "function ZERO_VALUE() view returns (uint256) @1000000",
            "function applyForFunding(address) @1000000",
            "function bounty() view returns (uint256) @1000000",
            "function checkUpkeep(bytes) returns (bool, bytes) @1000000",
            "function config() view returns (uint64, uint64, uint64) @1000000",
            "function currentRootIndex() view returns (uint32) @1000000",
            "function daoManager() view returns (address) @1000000",
            "function dkgContract() view returns (address) @1000000",
            "function filledSubtrees(uint256) view returns (uint256) @1000000",
            "function finalizeFundingRound(uint256) @1000000",
            "function founder() view returns (address) @1000000",
            "function fund(uint256,uint256,uint256[][],uint256[][],bytes) payable @1000000",
            "function fundingRoundCounter() view returns (uint256) @1000000",
            "function fundingRoundInProgress() view returns (bool) @1000000",
            "function fundingRoundQueue() view returns (address) @1000000",
            "function fundingRounds(uint256) view returns (bytes32, uint256, uint64, uint64, uint64, uint64) @1000000",
            "function getDKGParams() view returns (uint8, uint8) @1000000",
            "function getDistributedKeyID(bytes32) view returns (uint256) @1000000",
            "function getFundingRoundBalance(uint256) view returns (uint256) @1000000",
            "function getFundingRoundQueueLength() view returns (uint256) @1000000",
            "function getFundingRoundState(uint256) view returns (uint8) @1000000",
            "function getLastRoot() view returns (uint256) @1000000",
            "function getListDAO(uint256) view returns (address[]) @1000000",
            "function getRequestID(uint256,address,uint256) pure returns (bytes32) @1000000",
            "function hash(address,uint256,uint256) pure returns (uint256) @1000000",
            "function isCommittee(address) view returns (bool) @1000000",
            "function isFounder(address) view returns (bool) @1000000",
            "function isKnownRoot(uint256) view returns (bool) @1000000",
            "function launchFundingRound(uint256) returns (uint256, bytes32) @1000000",
            "function levels() view returns (uint32) @1000000",
            "function nextIndex() view returns (uint32) @1000000",
            "function numberOfCommittees() view returns (uint8) @1000000",
            "function performUpkeep(bytes) @1000000",
            "function poseidon() view returns (address) @1000000",
            "function refund(uint256) @1000000",
            "function requests(bytes32) view returns (uint256, uint256) @1000000",
            "function reserveFactor() view returns (uint256) @1000000",
            "function roots(uint256) view returns (uint256) @1000000",
            "function startTallying(uint256) @1000000",
            "function submitTallyResult(bytes32,uint256[]) @1000000",
            "function threshold() view returns (uint8) @1000000",
            "function withdrawFund(uint256,address) @1000000",
            "function zeros(uint32) view returns (uint256) @1000000"
        ]
    },
    "daomanager": {
        "address": "",
        "interface": [
            "constructor()",
            "event DAOCreated(uint256,address,address)",
            "function admin() view returns (address) @1000000",
            "function applyForFunding() @1000000",
            "function applyForFundingDev(address) @1000000",
            "function createDAO(uint256,tuple(uint32,uint32,uint32,uint32,uint32)) payable returns (uint256) @1000000",
            "function daoCounter() view returns (uint256) @1000000",
            "function daos(uint256) view returns (address) @1000000",
            "function deposits(address) view returns (uint256) @1000000",
            "function distributedKeyId() view returns (uint256) @1000000",
            "function dkg() view returns (address) @1000000",
            "function fundManager() view returns (address) @1000000",
            "function requiredDeposit() view returns (uint256) @1000000",
            "function setAdmin(address) @1000000",
            "function setDKG(address) @1000000",
            "function setDistributedKeyId(uint256) @1000000",
            "function setFundManager(address) @1000000",
            "function setRequiredDeposit(uint256) @1000000"
        ]
    },
    "dkg": {
        "address": "",
        "interface": [
            "constructor(tuple(address,address,address,address,address))",
            "event DistributedKeyActivated(uint256 indexed)",
            "event DistributedKeyGenerated(uint256 indexed)",
            "event Round1DataSubmitted(address indexed)",
            "event Round2DataSubmitted(address indexed)",
            "event TallyContributionSubmitted(address indexed)",
            "event TallyResultSubmitted(address indexed,bytes32 indexed,uint256[] indexed)",
            "event TallyStarted(bytes32 indexed)",
            "function distributedKeyCounter() view returns (uint256) @1000000",
            "function distributedKeys(uint256) view returns (uint8, uint8, uint8, uint8, address, uint256, uint256, uint256) @1000000",
            "function fundingVerifiers(uint256) view returns (address) @1000000",
            "function generateDistributedKey(uint8,uint8) returns (uint256) @1000000",
            "function getCommitteeIndex(address,uint256) view returns (uint8) @1000000",
            "function getDimension(uint256) view returns (uint8) @1000000",
            "function getDistributedKeyState(uint256) view returns (uint8) @1000000",
            "function getM(bytes32) view returns (uint256[][]) @1000000",
            "function getPublicKey(uint256) view returns (uint256, uint256) @1000000",
            "function getR(bytes32) view returns (uint256[][]) @1000000",
            "function getRound1DataSubmissions(uint256) view returns (tuple(address,uint8,uint256[],uint256[])[]) @1000000",
            "function getRound2DataSubmissions(uint256,uint8) view returns (tuple(uint8,uint256[])[]) @1000000",
            "function getTallyDataSubmissions(bytes32) view returns (tuple(uint8,uint256[][])[]) @1000000",
            "function getTallyTracker(bytes32) view returns (tuple(uint256,uint256[][],uint256[][],uint8,tuple(uint8,uint256[][])[],uint8,bool,address,address,address)) @1000000",
            "function getTallyTrackerState(bytes32) view returns (uint8) @1000000",
            "function getType(uint256) view returns (uint8) @1000000",
            "function getUsageCounter(uint256) view returns (uint256) @1000000",
            "function getVerifier(uint256) view returns (address) @1000000",
            "function owner() view returns (address) @1000000",
            "function resultVerifiers(uint256) view returns (address) @1000000",
            "function round2Verifier() view returns (address) @1000000",
            "function startTallying(bytes32,uint256,uint256[][],uint256[][]) @1000000",
            "function submitRound1Contribution(uint256,tuple(uint256[],uint256[])) returns (uint8) @1000000",
            "function submitRound2Contribution(uint256,tuple(uint8,uint8[],uint256[][],bytes)) @1000000",
            "function submitTallyContribution(bytes32,tuple(uint8,uint256[][],bytes)) @1000000",
            "function submitTallyResult(bytes32,uint256[],bytes) @1000000",
            "function tallyContributionVerifiers(uint256) view returns (address) @1000000",
            "function tallyTrackers(bytes32) view returns (uint256, uint8, uint8, bool, address, address, address) @1000000",
            "function votingVerifiers(uint256) view returns (address) @1000000"
        ]
    }
}