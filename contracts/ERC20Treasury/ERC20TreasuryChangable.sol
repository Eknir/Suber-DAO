import "./ERC20Treasury.sol";

pragma solidity ^0.4.24;

contract ERC20TreasuryChangable is ERC20Treasury {

    bytes32 constant public ERC20TREASURY_PERMISSION_01              = bytes32("ERC20TREASURY_PERMISSION_01");
    bytes32 constant public ERC20TREASURY_BUDGET_01                  = bytes32("ERC20TREASURY_BUDGET_01");
    bytes32 constant public ERC20TREASURY_PERIOD_01                  = bytes32("ERC20TREASURY_PERIOD_01");
    bytes32 constant public ERC20TREASURY_SAVEMULTIPLIER_01          = bytes32("ERC20TREASURY_SAVEMULTIPLIER_01");
    bytes32 constant public ERC20TREASURY_VOTINGENGINE_01            = bytes32("ERC20TREASURY_VOTINGENGINE_01");

    bytes32 constant public BYTES32_TRUE                             = bytes32("BYTES32_TRUE");
    bytes32 constant public BYTES32_FALSE                            = bytes32("BYTES32_FALSE");

    constructor(
        address[] initialSpenders,
        address[] initialERC20s,
        uint[] initialSpendBudgets,
        uint[] initialSpendBudgetPeriods,
        uint[] initialSpendMultipliers,
        address votingEngine
    ) ERC20Treasury(
        initialSpenders,
        initialERC20s,
        initialSpendBudgets,
        initialSpendBudgetPeriods,
        initialSpendMultipliers,
        votingEngine
    ) {
      //empty constructor
    }

    function setERC20TreasuryPermission(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20TREASURY_PERMISSION_01);
        bytes32 effectZero = votingEngine.getProposalEffectZero(proposalId);
        require(effectZero == BYTES32_TRUE || effectZero == BYTES32_FALSE);
        if(effectZero == bytes32(0)) {
            ERC20SpendingAllowanceRegistry
                [address(votingEngine.getProposalEffectOne(proposalId))]
                [address(votingEngine.getProposalEffectTwo(proposalId))].isAllowed = false;
        } else {
            ERC20SpendingAllowanceRegistry
                [address(votingEngine.getProposalEffectOne(proposalId))]
                [address(votingEngine.getProposalEffectTwo(proposalId))].isAllowed = true;
        }
    }

    function setERC20TreasuryBudget(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20TREASURY_BUDGET_01);
        ERC20SpendingAllowanceRegistry
            [address(votingEngine.getProposalEffectOne(proposalId))]
            [address(votingEngine.getProposalEffectTwo(proposalId))].budget =
                uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setERC20TreasuryPerdiod(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20TREASURY_PERIOD_01);
        ERC20SpendingAllowanceRegistry
            [address(votingEngine.getProposalEffectOne(proposalId))]
            [address(votingEngine.getProposalEffectTwo(proposalId))].period =
                uint256(votingEngine.getProposalEffectZero(proposalId));
    }

    function setERC20TreasurySaveMultiplier(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20TREASURY_SAVEMULTIPLIER_01);
        ERC20SpendingAllowanceRegistry
            [address(votingEngine.getProposalEffectOne(proposalId))]
            [address(votingEngine.getProposalEffectTwo(proposalId))].saveMultiplier =
                uint256(votingEngine.getProposalEffectZero(proposalId));
    }


    function setERC20TreasuryVotingEngine(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == ERC20TREASURY_VOTINGENGINE_01);
        votingEngine = VotingEngine(address(votingEngine.getProposalEffectZero(proposalId)));
    }
}
