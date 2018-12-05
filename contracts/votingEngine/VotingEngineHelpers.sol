// TODO: why do we only make a vote ineffect after votingWindow time?
import "./VotingEngine.sol";

pragma solidity ^0.4.24;

contract VotingEngineHelpers {

    mapping(bytes32 => bool) inEffect;

    //TODO, make an event here, because the votingEngine emits an event with the msg.sender (this account) as sender
    VotingEngine votingEngine;

    constructor(address _votingEngine) {
        votingEngine = VotingEngine(_votingEngine);
    }

    modifier applicableVote(bytes32 proposalId) {
        require(votingEngine.getProposalStatus(proposalId) == VotingEngine.ProposalStatus.Accepted);
        require(inEffect[proposalId] = false);
        inEffect[proposalId] = true;
        _;
    }
}
