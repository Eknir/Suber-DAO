//TODO: set trustedEtherFund function

import "./EtherTreasury.sol";
import "./../votingEngine/VotingEngineHelpers.sol";

pragma solidity ^0.4.24;

contract EtherTreasuryChangable is EtherTreasury, VotingEngineHelpers {

    bytes32 constant public ETHERTREASURY_PERMISSION_01           = bytes32("01_ETHERTREASURY_PERMISSION_01");
    bytes32 constant public ETHERTREASURY_BUDGET_01               = bytes32("ETHERTREASURY_BUDGET_01");
    bytes32 constant public ETHERTREASURY_PERIOD_01               = bytes32("ETHERTREASURY_PERIOD_01");
    bytes32 constant public ETHERTREASURY_SAVEMULTIPLIER_01       = bytes32("ETHERTREASURY_SAVEMULTIPLIER_01");
    bytes32 constant public ETHERTREASURY_VOTINGENGINE_01         = bytes32("ETHERTREASURY_VOTINGENGINE_01");
    bytes32 constant public ETHERTREASURY_ETHERFUND_01            = bytes32("ETHERTREASURY_ETHERFUND_01");

    bytes32 constant public BYTES32_TRUE                          = bytes32("BYTES32_TRUE");
    bytes32 constant public BYTES32_FALSE                         = bytes32("BYTES32_FALSE");

    constructor(
        address[] initialSpenders,
        uint256[] initialSpendBudgets,
        uint256[] initialSpendBudgetPeriods,
        uint256[] initialSpendMultipliers,
        address initialEtherFund,
        address votingEngine
        ) VotingEngineHelpers(
            votingEngine
        ) EtherTreasury(
            initialSpenders,
            initialSpendBudgets,
            initialSpendBudgetPeriods,
            initialSpendMultipliers,
            initialEtherFund
        ) {
          //empty constructor
      }

      function setEtherPermission(bytes32 proposalId)
          public
          applicableVote(proposalId)
      {
          require(votingEngine.getProposalSubject(proposalId) == ETHERTREASURY_PERMISSION_01);
          bytes32 effectZero = votingEngine.getProposalEffectZero(proposalId);
          require(effectZero == BYTES32_TRUE || effectZero == BYTES32_FALSE);
          if(effectZero == bytes32(0)) {
              etherAllowanceRegistry[address(votingEngine.getProposalEffectOne(proposalId))].isAllowed = false;
          } else {
              etherAllowanceRegistry[address(votingEngine.getProposalEffectOne(proposalId))].isAllowed = true;
            }
      }

      function setEtherBudget(bytes32 proposalId)
          public
          applicableVote(proposalId)
      {
          require(votingEngine.getProposalSubject(proposalId) == ETHERTREASURY_BUDGET_01);
          etherAllowanceRegistry[address(votingEngine.getProposalEffectOne(proposalId))].budget =
              uint256(votingEngine.getProposalEffectZero(proposalId));
      }

      function setEtherPeriod(bytes32 proposalId)
          public
          applicableVote(proposalId)
      {
          require(votingEngine.getProposalSubject(proposalId) == ETHERTREASURY_PERIOD_01);
          etherAllowanceRegistry[address(votingEngine.getProposalEffectOne(proposalId))].period =
              uint256(votingEngine.getProposalEffectZero(proposalId));
      }

      function setEtherSaveMultiplier(bytes32 proposalId)
          public
          applicableVote(proposalId)
      {
          require(votingEngine.getProposalSubject(proposalId) == ETHERTREASURY_SAVEMULTIPLIER_01);
          etherAllowanceRegistry[address(votingEngine.getProposalEffectOne(proposalId))].saveMultiplier =
              uint256(votingEngine.getProposalEffectZero(proposalId));
      }

      function setVotingEngine(bytes32 proposalId)
          public
          applicableVote(proposalId)
      {
          require(votingEngine.getProposalSubject(proposalId) == ETHERTREASURY_VOTINGENGINE_01);
          votingEngine = VotingEngine(address(votingEngine.getProposalEffectZero(proposalId)));
      }

      function setTrustedEtherFund(bytes32 proposalId)
          public
          applicableVote(proposalId)
      {
          require(votingEngine.getProposalSubject(proposalId) == ETHERTREASURY_ETHERFUND_01);
          trustedEtherFund[address(votingEngine.getProposalEffectZero(proposalId))] = true;
      }
}
