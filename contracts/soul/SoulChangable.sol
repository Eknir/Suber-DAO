import "./Soul.sol";
import "./../votingEngine/VotingEngineChangable.sol";
import "./../votingEngine/VotingEngineHelpers.sol";

pragma solidity ^0.4.24;

contract SoulChangable is Soul, VotingEngineHelpers  {

    bytes32 constant public SOUL_OBJECTIVES_01                  = bytes32("SOUL_OBJECTIVES_01");
    bytes32 constant public SOUL_PRINCIPLES_01                  = bytes32("SOUL_PRINCIPLES_01");
    bytes32 constant public SOUL_RULES_01                       = bytes32("SOUL_RULES_01");
    bytes32 constant public SOUL_VOTINGENGINE_01                = bytes32("SOUL_VOTINGENGINE_01");

    constructor(
        address votingEngine,
        bytes32 initialObjectives,
        bytes32 initialPrinciples,
        bytes32 initialRules
    ) VotingEngineHelpers(
        votingEngine
    ) Soul(
        initialObjectives,
        initialPrinciples,
        initialObjectives
    ) {
        // empty constructor
    }

    function setObjectives(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SOUL_OBJECTIVES_01);
        myObjectives = votingEngine.getProposalEffectZero(proposalId);
    }

    function setPrinciples(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SOUL_PRINCIPLES_01);
        myPrinciples = votingEngine.getProposalEffectZero(proposalId);
    }

    function setRules(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SOUL_PRINCIPLES_01);
        myRules = votingEngine.getProposalEffectZero(proposalId);
    }

    function setVotingEngine(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SOUL_VOTINGENGINE_01);
        votingEngine = VotingEngine(address(votingEngine.getProposalEffectZero(proposalId)));
    }
}
