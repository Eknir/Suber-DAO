//TODO: naming convention (votingEngine did not fit in bytes32 + minimumvouchers (not minimumvoucherstopropose))

import "./VotingEngine.sol";
import "./VotingEngineHelpers.sol";

pragma solidity ^0.4.24;

contract VotingEngineChangable is VotingEngine, VotingEngineHelpers {

    bytes32 constant public VOTINGENGINE_REFERENDUMQUOTUM_01          = bytes32("VOTING_REFERENDUMQUOTUM_01");
    bytes32 constant public VOTINGENGINE_MAJORITYQUOTUM_01            = bytes32("VOTING_MAJORITYQUOTUM_01");
    bytes32 constant public VOTINGENGINE_ASSEMBLYINTERVAL_01          = bytes32("VOTING_ASSEMBLYINTERVAL_01");
    bytes32 constant public VOTINGENGINE_ASSYMBLYDURATION_01          = bytes32("VOTING_ASSYMBLYDURATION_01");
    bytes32 constant public VOTINGENGINE_REVEALORCANCELWINDOW_01      = bytes32("VOTING_REVEALORCANCELWINDOW_01");
    bytes32 constant public VOTINGENGINE_MINIMUMVOUCHERSTOPROPOSE_01  = bytes32("VOTING_MINIMUMVOUCHERS_01");
    bytes32 constant public VOTINGENGINE_VOTINGWINDOW_01              = bytes32("VOTING_VOTINGWINDOW_01");


    constructor(
        uint256 referendumQuotum,
        uint256 majorityQuotum,
        uint256 assemblyInterval,
        uint256 assemblyDuration,
        uint256 votingWindow,
        uint256 revealOrCancelWindow,
        uint256 minimumVouchersToPropose,
        address voucherRegistry
    ) VotingEngineHelpers(
        address(this)
    ) VotingEngine(
        referendumQuotum,
        majorityQuotum,
        assemblyInterval,
        assemblyDuration,
        votingWindow,
        revealOrCancelWindow,
        minimumVouchersToPropose,
        voucherRegistry
    ) {
      // empty constructor
    }

    function setReferendumQuotum(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == VOTINGENGINE_REFERENDUMQUOTUM_01);
        uint256 effect = uint256(proposalRegistry[proposalId].effect[0]);
        require(effect <= 1000000); // 100%
        referendumQuotum = effect;
    }

    function setMajorityQuotum(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == VOTINGENGINE_MAJORITYQUOTUM_01);
        uint256 effect = uint256(proposalRegistry[proposalId].effect[0]);
        require(effect <= 1000000); // 100%
        majorityQuotum = effect;
    }

    function setAssemblyInterval(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == VOTINGENGINE_ASSEMBLYINTERVAL_01);
        assert(assemblyInterval * 4 >= assemblyInterval); // overflow check
        uint256 effect = uint256(proposalRegistry[proposalId].effect[0]);
        require(
            effect >= (assemblyInterval / 4) &&
            effect <= (assemblyInterval * 4)
        );
        assemblyInterval = effect;
    }

    function setAssemblyDuration(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == VOTINGENGINE_ASSYMBLYDURATION_01);
        assert(assemblyDuration * 4 >= assemblyDuration); // overflow check
        uint256 effect = uint256(proposalRegistry[proposalId].effect[0]);
        require(
            effect >= (assemblyDuration / 4) &&
            effect <= (assemblyDuration * 4)
        );
        assemblyDuration = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setVotingWindow(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject ==  VOTINGENGINE_REVEALORCANCELWINDOW_01);
        uint256 effect = uint256(proposalRegistry[proposalId].effect[0]);
        require(
            effect >= votingWindow / 4 &&
            effect <= assemblyInterval
        );
        votingWindow = effect;
    }

    function setRevealOrCancelWindow(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == VOTINGENGINE_MINIMUMVOUCHERSTOPROPOSE_01);
        assert(revealOrCancelWindow * 4 >= revealOrCancelWindow); // overflow check
        uint256 effect = uint256(proposalRegistry[proposalId].effect[0]);
        require(
            effect >= (revealOrCancelWindow / 4) &&
            effect <= (revealOrCancelWindow * 4)
        );
        revealOrCancelWindow = effect;
    }

    function setMinimumVouchersToPropose(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == VOTINGENGINE_VOTINGWINDOW_01);
        minimumVouchersToPropose = uint256(proposalRegistry[proposalId].effect[0]);
    }
}
