import "./Slasher.sol";
import "./../votingEngine/VotingEngineHelpers.sol";

pragma solidity ^0.4.24;

contract SlasherChangable is Slasher, VotingEngineHelpers {

    bytes32 constant public SLASHER_PROPOSERSLASH_01              = bytes32("SLASHER_PROPOSERSLASH_01");
    bytes32 constant public SLASHER_VOTERSLASH_01                 = bytes32("SLASHER_VOTERSLASH_01");
    bytes32 constant public SLASHER_NONVOTERSLASH_01              = bytes32("SLASHER_NONVOTERSLASH_01");
    bytes32 constant public SLASHER_SLASHERWINDOW_01              = bytes32("SLASHER_SLASHERWINDOW_01");
    bytes32 constant public SLASHER_VOTINGENGINE_01               = bytes32("SLASHER_VOTINGENGINE_01");


    constructor(
        uint256 proposerSlash,
        uint256 voterSlash,
        uint256 nonVoterSlash,
        uint256 slasherWindow,
        address voucherRegistry,
        address votingEngine
    ) VotingEngineHelpers(
        votingEngine
    ) Slasher(
        proposerSlash,
        voterSlash,
        nonVoterSlash,
        slasherWindow,
        voucherRegistry
    ) {
        // empty constructor
    }

    function setProposerSlash(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_PROPOSERSLASH_01);

    }

    function setVoterSlash(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_VOTERSLASH_01);
        //TODO
    }

    function setNonVoterSlash(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_NONVOTERSLASH_01);
        //TODO
    }

    function setSlasherWindow(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_SLASHERWINDOW_01);
        //TODO
    }

    function setVotingEngine(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_VOTINGENGINE_01);
    }

}
