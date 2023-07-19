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

    event LeafInserted(uint32 indexed index, uint256 indexed commitment);

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
        index = nextIndex;
        require(
            index != uint32(2) ** levels,
            "Merkle tree is full. No more leaves can be added"
        );
        uint32 currentIndex = index;
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
        nextIndex = index + 1;
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
                    17049707378559488635014311045431300269072114040192289006854544739567595837026
                );
        else if (i == 2)
            return
                uint256(
                    2024664126807287169908459638633400210764462839178307486421496669109544526902
                );
        else if (i == 3)
            return
                uint256(
                    15302233528709839636005576996333976670730928169033426462685439703534517173221
                );
        else if (i == 4)
            return
                uint256(
                    10663299044566417476624793175581702676671851060868557827915476903917685603026
                );
        else if (i == 5)
            return
                uint256(
                    11224692797492880339593802278966388185866696989730516777029846917193259075922
                );
        else if (i == 6)
            return
                uint256(
                    10462105357415906316383407827245398225740131341230821795145628438622794367015
                );
        else if (i == 7)
            return
                uint256(
                    8528899714407140404708627696500190296632177812503149764277961288293916337644
                );
        else if (i == 8)
            return
                uint256(
                    10893238003998436915934164579628259589258118467665162763042880753262257390377
                );
        else if (i == 9)
            return
                uint256(
                    228007269351501436658293871201846897213912817484401330594542576160563390028
                );
        else if (i == 10)
            return
                uint256(
                    8845203158900471260045169378714292234951549368330264683636346677985906803503
                );
        else if (i == 11)
            return
                uint256(
                    17840603213899575103617622419410228698652917994058739827872516936941468231765
                );
        else if (i == 12)
            return
                uint256(
                    20985564329841138444086033197456329195012117385041709391730557931456880984714
                );
        else if (i == 13)
            return
                uint256(
                    11139265878017831544435196240114657711268950226982070933066590889968268145893
                );
        else if (i == 14)
            return
                uint256(
                    20335101146101564653255261096521464730048471427960686043001552479381257596549
                );
        else if (i == 15)
            return
                uint256(
                    14060763361080496592859811555833128007678404729356375027255968239826901532724
                );
        else if (i == 16)
            return
                uint256(
                    17228493528255163219882482718076738020390565561786231062907112367781333290408
                );
        else if (i == 17)
            return
                uint256(
                    20712285184589533416626475745484910428741438011329053741242021602324364492516
                );
        else if (i == 18)
            return
                uint256(
                    6460352945134146019478416780922003332985308785194826631789738002580550234532
                );
        else if (i == 19)
            return
                uint256(
                    21546679390975531284940508542025721071309829946049285965861132367012462146894
                );
        else if (i == 20)
            return
                uint256(
                    18732921926890229222071246946241431999123147163170008520638424078404773080933
                );
        else if (i == 21)
            return
                uint256(
                    9079802649488407889414002998582230609382406304491500245345779813821708376398
                );
        else if (i == 22)
            return
                uint256(
                    20739809963444662969560390651398663000206875386271838332943261642251049354519
                );
        else if (i == 23)
            return
                uint256(
                    6250163281864133767262488846473725744360066789134402126392355979770426845298
                );
        else if (i == 24)
            return
                uint256(
                    14497981311527614426481693917917845616088855761294189447585172933028965743558
                );
        else if (i == 25)
            return
                uint256(
                    18268773173817170701845880266424017582565900187417363302464053503141111113418
                );
        else if (i == 26)
            return
                uint256(
                    13531294554047541157365667284610457977379259929075664698082236327434671640288
                );
        else if (i == 27)
            return
                uint256(
                    3068708164219332199583960663856408052987217100896411443359983011007053843977
                );
        else if (i == 28)
            return
                uint256(
                    6007617635966522363161298629611303377963511407569103032654910374569866920965
                );
        else if (i == 29)
            return
                uint256(
                    9776547671266463162123288502928766152070241483996892081609183436429752211478
                );
        else if (i == 30)
            return
                uint256(
                    20761180717883809312710891741959508212151146931500583236392931280126115123721
                );
        else if (i == 31)
            return
                uint256(
                    21277995670127745977920955093507893285965099247814090335957439707302853728467
                );
        else revert("Index out of bounds");
    }
}
