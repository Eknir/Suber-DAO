import "./../votingEngine/VotingEngineHelpers.sol";
import "./EtherFund.sol";

pragma solidity ^0.4.24;

contract EtherFundChangable is EtherFund, VotingEngineHelpers {

    bytes32 constant public ETHERFUND_ALLOWEDADDRESSES_01               = bytes32("ETHERFUND_ALLOWEDADDRESSES_01");
    bytes32 constant public BYTES32_TRUE                                = bytes32("BYTES32_TRUE");
    bytes32 constant public BYTES32_FALSE                               = bytes32("BYTES32_FALSE");
    constructor(
        address initialEtherTreasury,
        address votingEngine
    ) VotingEngineHelpers(
        votingEngine
    ) EtherFund(
      initialEtherTreasury
    ) {
        // empty constructor
    }

    function setAllowedAddresses(bytes32 proposalId) public {
        require(votingEngine.getProposalSubject(proposalId) == ETHERFUND_ALLOWEDADDRESSES_01);
        bytes32 effect0 = votingEngine.getProposalEffectZero(proposalId);
        require(effect0 == BYTES32_TRUE || effect0 == BYTES32_FALSE);
        if(effect0 == BYTES32_FALSE) {
            allowedAddresses[address(votingEngine.getProposalEffectOne(proposalId))] = false;
        } else {
            allowedAddresses[address(votingEngine.getProposalEffectOne(proposalId))] = true;
        }
    }
}
