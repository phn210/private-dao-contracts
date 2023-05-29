// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IDKGRequest.sol';

interface IDAO {
    enum ProposalState {
        Pending,
        Active,
        Tallying,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum VoteOption {
        Against,
        For,
        Abstain
    }

    struct Config {
        uint32 pendingPeriod;
        uint32 votingPeriod;
        uint32 tallyingPeriod;
        uint32 timelockPeriod;
        uint32 queuingPeriod;
    }

    struct Proposal {
        uint256 id;             // Unique hash for looking up a proposal.
        uint256 forVotes;       // Current number of votes in favor of this proposal.
        uint256 againstVotes;   // Current number of votes in opposition to this proposal.
        uint256 abstainVotes;   // Current number of votes in abstain to this proposal.
        uint64 startBlock;      // The block at which voting begins: veTrava must be locked prior to this block to possess voting power.
        uint32 eta;             // The block that the proposal will be available for execution, set once the vote succeeds.
        bool canceled;          // Flag marking whether the proposal has been canceled.
        bool executed;          // Flag marking whether the proposal has been executed.
    }

    struct Action {
        address target;
        uint256 value;
        string signature;
        bytes data;
    }

    /**
     * @notice Emitted when a valid proposal is created.
     */
    event ProposalCreated(
        uint256 index,
        uint256 proposalId,
        address proposer,
        Action[] actions,
        uint256 startBlock,
        bytes32 descriptionHash
    );

    /**
     * @notice Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    event ProposalTallyingStarted(
        uint256 proposalId,
        bytes32 requestId
    );

    /**
     * @notice Emitted when a valid proposal is created.
     */
    event ProposalFinalized(
        uint256 proposalId, // Unique hash for looking up a proposal.
        uint256 forVotes, // Current number of votes in favor of this proposal.
        uint256 againstVotes, // Current number of votes in opposition to this proposal.
        uint256 abstainVotes // Current number of votes in abstain to this proposal.
    );

    /**
     * @notice Emitted when a proposal is queued in the Timelock.
     */
    event ProposalQueued(uint256 proposalId, uint32 eta);

    /**
     * @notice Emitted when a proposal is executed from Timelock.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev FIXME update for ZKP
     * @notice Emitted when a vote casted.
     */
    event VoteCast(uint256 proposalId);

    function propose(Action[] memory actions, bytes32 descriptionHash) external returns (uint256 proposalId);

    function queue(Action[] memory actions, bytes32 descriptionHash) external;

    function execute(Action[] memory actions, bytes32 descriptionHash) external payable;

    function cancel(Action[] memory actions, bytes32 descriptionHash) external;

    function castVote(
        uint256 proposalId,
        uint256 _commitment,
        uint256[][] calldata _R,
        uint256[][] calldata _M,
        bytes calldata _proof
    ) external;

    function tally(uint256 proposalId) external;

    function finalize(uint256 proposalId) external;

}