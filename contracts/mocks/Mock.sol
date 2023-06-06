pragma solidity ^0.8.0;

contract Mock {

    address public governor;

    uint256 public interestRate;

    modifier onlyGovernor() {
        require(msg.sender == governor, "Mock: only governor address");
        _;
    }

    constructor(address _governor) {
        governor = _governor;
    }

    function setInterestRate(uint256 newRate) external onlyGovernor {
        interestRate = newRate;
    }

}