import "./../votingEngine/VotingEngineHelpers.sol";
import "./ERC20Fund.sol";

pragma solidity ^0.4.24;

contract ERC20FundChangable is ERC20Fund, VotingEngineHelpers {

    bytes32 constant public ERC20FUND_ALLOWEDADDRESSES_01              = bytes32("ERC20FUND_ALLOWEDADDRESSES_01");

    bytes32 constant public BYTES32_TRUE                             = bytes32("BYTES32_TRUE");
    bytes32 constant public BYTES32_FALSE                            = bytes32("BYTES32_FALSE");

    constructor(
        address initialERC20Treasury,
        address votingEngine
    ) VotingEngineHelpers(
        votingEngine
    ) EtherFund(
      initialERC20Treasury
    ) {
        // empty constructor
    }

    function setAllowedAddresses(bytes32 proposalId) public {
        require(votingEngine.getProposalSubject(proposalId) == ERC20FUND_ALLOWEDADDRESSES_01);
        bytes32 effect0 = votingEngine.getProposalEffectZero(proposalId);
        require(effect0 == BYTES32_TRUE || effect0 == BYTES32_FALSE);
        if(effect0 == BYTES32_FALSE) {
            allowedAddresses[address(votingEngine.getProposalEffectOne(proposalId))] = false;
        } else {
            allowedAddresses[address(votingEngine.getProposalEffectOne(proposalId))] = true;
        }
    }
}
