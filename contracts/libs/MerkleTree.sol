// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

interface IPoseidon {
    function hash(uint256[2] calldata input) external pure returns (uint256);
}

contract MerkleTree {
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public ZERO_VALUE =
        0x0278878f9bf771ee0d3ecbd67f02536af7696dea0a6fa6acccadcacefb2ae2d9;
    //keccak256(abi.encodePacked("zkVN"));
    IPoseidon public immutable poseidon;
    uint32 public levels;

    mapping(uint256 => uint256) public filledSubtrees;
    mapping(uint256 => uint256) public roots;

    uint32 public constant ROOT_HISTORY_SIZE = 20;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    constructor(uint32 _levels, IPoseidon _poseidon) {
        require(_levels > 0, "level should be greater than zero");
        require(_levels <= 32, "level should be less than 32");
        levels = _levels;
        poseidon = _poseidon;

        for (uint32 i = 0; i < _levels; i++) {
            filledSubtrees[i] = zeros(i);
        }
        roots[0] = zeros(_levels - 1);
    }

    function hash(
        IPoseidon hasher,
        uint256 _left,
        uint256 _right
    ) public pure returns (uint256) {
        require(_left < FIELD_SIZE, "_left should be inside the field");
        require(_right < FIELD_SIZE, "_right should be inside the field");

        return hasher.hash([_left, _right]);
    }

    function _insert(uint256 _leaf) internal returns (uint32 index) {
        uint32 _nextIndex = nextIndex;
        require(
            _nextIndex != uint32(2) ** levels,
            "Merkle tree is full. No more leaves can be added"
        );
        uint32 currentIndex = _nextIndex;
        uint256 currentLevelsHash = _leaf;
        uint256 left;
        uint256 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelsHash;
                right = zeros(i);
                filledSubtrees[i] = currentLevelsHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelsHash;
            }
            currentLevelsHash = hash(poseidon, left, right);
            currentIndex /= 2;
        }

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelsHash;
        nextIndex = _nextIndex + 1;
        return _nextIndex;
    }

    function _insertBatch(uint256[] memory _leafs) internal {
        uint32 levels_ = levels;
        uint256[] memory filledSubtrees_ = new uint256[](levels_);
        for (uint32 i; i < levels_; i++) {
            filledSubtrees_[i] = filledSubtrees[i];
        }
        uint32 nextIndex_ = nextIndex;
        uint256 currentLevelsHash;
        uint256 left;
        uint256 right;
        uint32 currentIndex;
        for (uint32 i; i < _leafs.length; i++) {
            require(
                nextIndex_ != uint32(2) ** levels,
                "Merkle tree is full. No more leaves can be added"
            );
            currentIndex = nextIndex_;
            currentLevelsHash = _leafs[i];
            for (uint32 j = 0; j < levels_; j++) {
                if (currentIndex % 2 == 0) {
                    left = currentLevelsHash;
                    right = zeros(j);
                    filledSubtrees_[j] = currentLevelsHash;
                } else {
                    left = filledSubtrees_[j];
                    right = currentLevelsHash;
                }
                currentLevelsHash = hash(poseidon, left, right);
                currentIndex /= 2;
            }
            nextIndex_ += 1;
        }
        for (uint32 i; i < levels; i++) {
            filledSubtrees[i] = filledSubtrees_[i];
        }
        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelsHash;
        nextIndex = nextIndex_;
    }

    function isKnownRoot(uint256 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
            if (_root == roots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }

    function getLastRoot() public view returns (uint256) {
        return roots[currentRootIndex];
    }

    function zeros(uint32 i) public view returns (uint256) {
        if (i == 0) return uint256(ZERO_VALUE);
        else if (i == 1)
            return
                uint256(
                    20713138055499442757791137029881429088092083702570151560708500432139838298181
                );
        else if (i == 2)
            return
                uint256(
                    18929175140213929391726198295761599938460211974850692442469835017913592493517
                );
        else if (i == 3)
            return
                uint256(
                    680321276570412421209455636913908707867021698239763291355610926722331439424
                );
        else if (i == 4)
            return
                uint256(
                    2658949942030933000170164041810547489575273893891093479880751660626937107342
                );
        else if (i == 5)
            return
                uint256(
                    15712243705999882128713486017857002252859933276793472465759028833088163220376
                );
        else if (i == 6)
            return
                uint256(
                    14813175305411489861493518966902853264693042265431974191869968528104698356967
                );
        else if (i == 7)
            return
                uint256(
                    10356943906404696315499920274806696393843266779605808500278099242457132937443
                );
        else if (i == 8)
            return
                uint256(
                    7682628441804541520493985301260656242615116029623759731563509386049042540615
                );
        else if (i == 9)
            return
                uint256(
                    2526198932979519192766425523474232825597949693631346017055998431098850514778
                );
        else if (i == 10)
            return
                uint256(
                    21093327883200565186012050219534766804269603984571254898452966675384819447904
                );
        else if (i == 11)
            return
                uint256(
                    11298978038895523538876688837181543243805818177890213519872745452802091444819
                );
        else if (i == 12)
            return
                uint256(
                    6921930063852222157979899223941840920648446227577401156721880144617868779554
                );
        else if (i == 13)
            return
                uint256(
                    19917481261571894689246470858989965579071918964126177492287041037562815365447
                );
        else if (i == 14)
            return
                uint256(
                    4622828589572410840113646164198522452673072629097082711451146744175987812169
                );
        else if (i == 15)
            return
                uint256(
                    18827708575730685627508885664880560760849660087404462502867278948474426680464
                );
        else if (i == 16)
            return
                uint256(
                    14559598935247754121088252275555271638983947645733808573819901304181061035870
                );
        else if (i == 17)
            return
                uint256(
                    12002729310312233034786361030926258651079923029256944078182984851252117101709
                );
        else if (i == 18)
            return
                uint256(
                    18002224808306908875741810963398766034634855756755714242625708278562402399156
                );
        else if (i == 19)
            return
                uint256(
                    18474400199856589938206228344704999339211212411822141216891659416947934704449
                );
        else if (i == 20)
            return
                uint256(
                    9644548778005170100462477669123961025194477335774101779692367063373759151519
                );
        else if (i == 21)
            return
                uint256(
                    17758551601313080684421501701325706546543488656212069754944484638047162075947
                );
        else if (i == 22)
            return
                uint256(
                    6615033656740415522497359899730883752064153303747955123085217028900474457519
                );
        else if (i == 23)
            return
                uint256(
                    11559860077170472589126421009081351492161832713972292845454663204093184191185
                );
        else if (i == 24)
            return
                uint256(
                    12069908240502833736627352789553137826764470603204478048646357747128611420417
                );
        else if (i == 25)
            return
                uint256(
                    11535786370541913522434544545971238643710357229209065377781422213186957971662
                );
        else if (i == 26)
            return
                uint256(
                    21773775938353668071865822027100480017212279643465524560419600586116754428646
                );
        else if (i == 27)
            return
                uint256(
                    2701282298110273576507266445257941314997538287992929159751891490552309827117
                );
        else if (i == 28)
            return
                uint256(
                    3043405640347233986933066624847424044701786063811238204246027260622141056547
                );
        else if (i == 29)
            return
                uint256(
                    855915330225193428519277195250355253939462452357411164544999870171188208220
                );
        else if (i == 30)
            return
                uint256(
                    7331194058374476680432714874894230551666523125442714526591144073441149721333
                );
        else if (i == 31)
            return
                uint256(
                    12574290476933150018993197449726178974065507512729731012385493922295055077355
                );
        else revert("Index out of bounds");
    }
}
