//TODO: allowedAddresses did not fit in a bytes32 (ln 10). Do something with the naming convention. 

import "./VoucherRegistry.sol";
import "./../votingEngine/VotingEngineHelpers.sol";

pragma solidity ^0.4.24;

contract VoucherRegistryChangable is VoucherRegistry, VotingEngineHelpers {

    bytes32 constant public VOUCHERREGISTRY_ALLOWEDADRESSES_01          = bytes32("VOUCHERREGISTRY_ADRESSES_01");

    bytes32 constant public BYTES32_TRUE                             = bytes32("BYTES32_TRUE");
    bytes32 constant public BYTES32_FALSE                            = bytes32("BYTES32_FALSE");

    constructor(
        address slasher,
        address voucherMintGuardian,
        address votingEngine
    ) VotingEngineHelpers(
        votingEngine
    ) VoucherRegistry(
        slasher,
        voucherMintGuardian
    ) {
        // empty constructor
    }

    function setAllowedAddresses(bytes32 proposalId) public {
        require(votingEngine.getProposalSubject(proposalId) == VOUCHERREGISTRY_ALLOWEDADRESSES_01);
        bytes32 effect0 = votingEngine.getProposalEffectZero(proposalId);
        require(effect0 == BYTES32_TRUE || effect0 == BYTES32_FALSE);
        if(effect0 == bytes32(0)) {
            allowedAddresses[address(votingEngine.getProposalEffectOne(proposalId))] = false;
        } else {
            allowedAddresses[address(votingEngine.getProposalEffectOne(proposalId))] = true;
        }
    }
}
