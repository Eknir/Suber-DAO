import "./ERC20MintGuardian.sol";
import "./../votingEngine/VotingEngineHelpers.sol";

// TODO: naming convention of the subjects + make them a constant variable
pragma solidity ^0.4.24;

contract ERC20MintGuardianChangable is ERC20MintGuardian {

    bytes32 constant public ERC20MINTGUARDIAN_PERMISSION_01          = bytes32("ERC20MINT_PERMISSION_01");
    bytes32 constant public ERC20MINTGUARDIAN_BUDGET_01              = bytes32("ERC20MINT_BUDGET_01");
    bytes32 constant public ERC20MINTGUARDIAN_PERIOD_01              = bytes32("ERC20MINT_BUDGET_01");
    bytes32 constant public ERC20MINTGUARDIAN_SAVEMULTIPLIER_01      = bytes32("ERC20MINT_SAVEMULTIPLIER_01");
    bytes32 constant public ERC20MINTGUARDIAN_VOTINGENGINE_01        = bytes32("ERC20MINT_VOTINGENGINE_01");

    bytes32 constant public BYTES32_TRUE                             = bytes32("BYTES32_TRUE");
    bytes32 constant public BYTES32_FALSE                            = bytes32("BYTES32_FALSE");


    constructor(
        address initialERC20Mint,
        address[] initialSpenders,
        uint[] initialSpendBudgets,
        uint[] initialSpendBudgetPeriods,
        uint[] initialSpendMultipliers,
        address votingEngine
    ) ERC20MintGuardian(
        initialERC20Mint,
        initialSpenders,
        initialSpendBudgets,
        initialSpendBudgetPeriods,
        initialSpendMultipliers,
        votingEngine
    ) {
      // empty constructor
    }

    function setERC20MintPermission(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20MINTGUARDIAN_PERMISSION_01);
        bytes32 effectZero = votingEngine.getProposalEffectZero(proposalId);
        require(effectZero == BYTES32_TRUE || effectZero == BYTES32_FALSE);
        if(effectZero == bytes32(0)) {
            ERC20MintingAllowanceRegistry
                [address(votingEngine.getProposalEffectOne(proposalId))]
                [address(votingEngine.getProposalEffectTwo(proposalId))].isAllowed = false;
        } else {
            ERC20MintingAllowanceRegistry
                [address(votingEngine.getProposalEffectOne(proposalId))]
                [address(votingEngine.getProposalEffectTwo(proposalId))].isAllowed = true;
        }
    }

    function setERC20MintBudget(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20MINTGUARDIAN_BUDGET_01);
        ERC20MintingAllowanceRegistry
            [address(votingEngine.getProposalEffectOne(proposalId))]
            [address(votingEngine.getProposalEffectTwo(proposalId))].budget =
                uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setERC20MintPeriod(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20MINTGUARDIAN_BUDGET_01);
        ERC20MintingAllowanceRegistry
            [address(votingEngine.getProposalEffectOne(proposalId))]
            [address(votingEngine.getProposalEffectTwo(proposalId))].period =
                uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setERC20MintSaveMultiplier(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20MINTGUARDIAN_SAVEMULTIPLIER_01);
        ERC20MintingAllowanceRegistry
            [address(votingEngine.getProposalEffectOne(proposalId))]
            [address(votingEngine.getProposalEffectTwo(proposalId))].saveMultiplier =
                uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setVotingEngine(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20MINTGUARDIAN_VOTINGENGINE_01);
        votingEngine = VotingEngine(address(votingEngine.getProposalEffectZero(proposalId)));
    }
}
