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
        uint8 proposerSlash,
        uint8 voterSlash,
        uint8 nonVoterSlash,
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
        uint8 _proposerSlash = uint8(votingEngine.getProposalEffectZero(proposalId));
        require(_proposerSlash <= 100);
        proposerSlash = _proposerSlash;
    }

    function setVoterSlash(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_VOTERSLASH_01);
        uint8 _voterSlash = uint8(votingEngine.getProposalEffectZero(proposalId));
        require(_voterSlash <= 100);
        voterSlash = _voterSlash;
    }

    function setNonVoterSlash(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_NONVOTERSLASH_01);
        uint8 _nonVoterSlash = uint8(votingEngine.getProposalEffectZero(proposalId));
        require(_nonVoterSlash <= 100);
        nonVoterSlash = _nonVoterSlash;
    }

    function setSlasherWindow(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_SLASHERWINDOW_01);
        slasherWindow = uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setVotingEngine(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == SLASHER_VOTINGENGINE_01);
        votingEngine = VotingEngine(address(votingEngine.getProposalEffectZero(proposalId)));
    }

}
