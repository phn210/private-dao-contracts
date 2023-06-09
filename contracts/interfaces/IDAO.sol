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

    enum UpkeepAction {
        Tally,
        Finalize,
        Queue,
        Execute
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
        address proposer;
        uint64 startBlock;      // The block at which voting begins: veTrava must be locked prior to this block to possess voting power.
        bool canceled;          // Flag marking whether the proposal has been canceled.
        bool executed;          // Flag marking whether the proposal has been executed.
        uint256 eta;             // The block that the proposal will be available for execution, set once the vote succeeds.
    }

    struct Action {
        address target;
        uint256 value;
        string signature;
        bytes data;
    }

    struct VoteData {
        uint256 root;
        uint256 nullifierHash;
        uint256[][] _R;
        uint256[][] _M;
        bytes _proof;
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
    event ProposalQueued(uint256 proposalId, uint256 eta);

    /**
     * @notice Emitted when a proposal is executed from Timelock.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev FIXME update for ZKP
     * @notice Emitted when a vote casted.
     */
    event VoteCast(uint256 proposalId, uint256 nullifierHash);

    function propose(Action[] memory _actions, bytes32 _descriptionHash) external returns (uint256 proposalId);

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external payable;

    function cancel(uint256 proposalId) external;

    function castVote(
        uint256 proposalId,
        VoteData calldata voteData
    ) external;

    function tally(uint256 proposalId) external;

    function finalize(uint256 proposalId) external;

}