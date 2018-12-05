//TODO: REMOVE THE GUARDIAN IN THE ANME OF THE ERC20 MINT AND VOUCHERMINT

import "./VoucherMintGuardian.sol";
import "./../votingEngine/VotingEngineChangable.sol";
import "./../votingEngine/VotingEngineHelpers.sol";

pragma solidity ^0.4.24;

contract VoucherMintGuardianChangeable is VoucherMintGuardian, VotingEngineHelpers  {

    bytes32 constant public VOUCHERMINTGUARDIAN_PERMISSION_01          = bytes32("VOUCHERMINT_PERMISSION_01");
    bytes32 constant public VOUCHERMINTGUARDIAN_BUDGET_01              = bytes32("VOUCHERMINT_BUDGET_01");
    bytes32 constant public VOUCHERMINTGUARDIAN_PERIOD_01              = bytes32("VOUCHERMINT_PERIOD_01");
    bytes32 constant public VOUCHERMINTGUARDIAN_SAVEMULTIPLIER_01      = bytes32("VOUCHERMMINT_SAVEMULTIPLIER_01");
    bytes32 constant public VOUCHERMINTGUARDIAN_VOTINGENGINE_01         = bytes32("VOUCHERMINTVOTINGENGINE_01");

    bytes32 constant public BYTES32_TRUE                             = bytes32("BYTES32_TRUE");
    bytes32 constant public BYTES32_FALSE                            = bytes32("BYTES32_FALSE");

    constructor(
        address votingEngine,
        address[] initialMinters,
        uint256[] initialBudgets,
        uint256[] initialMintBudgetPeriods,
        uint256[] initialMintSaveMultipliers,
        address voucherRegistry
    ) VotingEngineHelpers(
        votingEngine
    ) VoucherMintGuardian(
        initialMinters,
        initialBudgets,
        initialMintBudgetPeriods,
        initialMintSaveMultipliers,
        voucherRegistry
    ) {
        // Empty constructor
    }

    function setVoucherMintPermission(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == VOUCHERMINTGUARDIAN_PERMISSION_01);
        bytes32 effectZero = votingEngine.getProposalEffectZero(proposalId);
        require(effectZero == BYTES32_TRUE || effectZero == BYTES32_FALSE);
        if(effectZero == BYTES32_FALSE) {
            voucherMintRegistry[address(votingEngine.getProposalEffectOne(proposalId))].isAllowed = false;
        } else {
            voucherMintRegistry[address(votingEngine.getProposalEffectOne(proposalId))].isAllowed = true;
        }
    }

    function setVoucherMintBudget(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == VOUCHERMINTGUARDIAN_BUDGET_01);
        voucherMintRegistry[address(votingEngine.getProposalEffectOne(proposalId))].budget =
            uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setVoucherMintPeriod(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == VOUCHERMINTGUARDIAN_PERIOD_01);
        voucherMintRegistry[address(votingEngine.getProposalEffectOne(proposalId))].period =
            uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setVoucherMintSaveMultiplier(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == VOUCHERMINTGUARDIAN_SAVEMULTIPLIER_01);
        voucherMintRegistry[address(votingEngine.getProposalEffectOne(proposalId))].saveMultiplier =
            uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setVotingEngine(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == VOUCHERMINTGUARDIAN_VOTINGENGINE_01);
        votingEngine = VotingEngine(address(votingEngine.getProposalEffectZero(proposalId)));
    }
}
