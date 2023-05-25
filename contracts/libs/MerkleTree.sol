// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoseidon {
    function hash(uint256[2] calldata input) external pure returns (uint256);
}

contract MerkleTree {
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    IPoseidon public immutable poseidon;
    uint32 public levels;

    mapping(uint256 => uint256) public filledSubtrees;
    mapping(uint256 => uint256) public roots;

    uint32 public constant ROOT_HISTORY_SIZE = 20;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    constructor(uint32 _levels, IPoseidon _poseidon) {
        require(_levels > 0, "level should be greater than zero");
        require(_levels <= 12, "level should be less than 12");
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

    function zeros(uint32 i) public pure returns (uint256) {
        if (i == 0) return uint256(0);
        else if (i == 1)
            return
                uint256(
                    951383894958571821976060584138905353883650994872035011055912076785884444545
                );
        else if (i == 2)
            return
                uint256(
                    20622346557934808217011721426661266483227782601688308996572323237868248378218
                );
        else if (i == 3)
            return
                uint256(
                    9824383624068251658076004948987922624579386843373418302611235390446333218543
                );
        else if (i == 4)
            return
                uint256(
                    18231051098028563566680291532078429851434716680352819569730767461390496150778
                );
        else if (i == 5)
            return
                uint256(
                    3353212758970507511129878484465451720398128800239371146311683143363228006106
                );
        else if (i == 6)
            return
                uint256(
                    11217981488147314489933157152414929198080353151522289497544152685671318494641
                );
        else if (i == 7)
            return
                uint256(
                    15036778088095722022055958830077231912659267101273997428998619074916612435352
                );
        else if (i == 8)
            return
                uint256(
                    13902072967731839344862497510839651364835012530289392251474510732102392496571
                );
        else if (i == 9)
            return
                uint256(
                    11544666763895735667784949329006117565540509653060441453303165109269815573544
                );
        else if (i == 10)
            return
                uint256(
                    21510646961350375150419802995301138938521651775264825801359130949650284310444
                );
        else if (i == 11)
            return
                uint256(
                    8352951083833165756052596980166442098457751367763718836446899882180191056793
                );
    }
}
