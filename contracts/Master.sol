//TODO, implement overflow checks for multiplications (1)
//TODO, change naming of afterApplicableVote
pragma solidity ^0.4.24;

import "./VoucherTreasury.sol";
import "./Slasher.sol";
import "./EtherTreasury.sol";
import "./SponsorRegistry.sol";

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Master
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The Master registers the hashes of the statutary goals and objectives of the DAO and makes sure all parameters can be updated when voted for
 */
contract Master is VoucherTreasury, Slasher, EtherTreasury, SponsorRegistry {

    using SafeMath for uint256;

    bytes32 public statutaryGoalsHash;
    bytes32 public statutaryRulesHash;

    constructor(
        bytes32 _statutaryGoalsHash,
        bytes32 _statutaryRulesHash,
        uint256 lastVote
    )
    {
        statutaryGoalsHash = _statutaryGoalsHash;
        statutaryRulesHash = _statutaryRulesHash;
    }

    event logUpgraded(
        address indexed callee,
        bytes32 proposalId
    );

    modifier mustBeAccepted(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Accepted);
        _;
    }

    modifier afterApplicableVote(bytes32 proposalId) {
      _;
      proposalRegistry[proposalId].status == ProposalStatus.InEffect;
      emit logUpgraded(msg.sender, proposalId);
    }

    function setSuperUpgrade(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("SUPER_UPGRADE"));
        // TODO, see 1
        require(uint256(proposalRegistry[proposalId].effect[0]) <= (assemblyInterval * 4));
        isUpgraded = true;
        whenClosed = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setReferendumQuotum(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("REFERENDUM_QUOTUM"));
        require(uint256(proposalRegistry[proposalId].effect[0]) <= 1000000); // 100%
        referendumQuotum = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setMajorityQuotum(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("MAJORITY_QUOTUM"));
        require(uint256(proposalRegistry[proposalId].effect[0]) <= 1000000); // 100%
        majorityQuotum = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setMinimumVouchersToPropose(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("MINIMUM_VOUCHERS_TO_PROPOSE"));
        minimumVouchersToPropose = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setAssemblyInterval(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("ASSEMBLY_PERIOD"));
        assert(assemblyInterval * 4 >= assemblyInterval);
        require(uint256(proposalRegistry[proposalId].effect[0]) >= assemblyInterval / 4 && uint256(proposalRegistry[proposalId].effect[0]) <= (assemblyInterval * 4));
        assemblyInterval = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setVotingWindow(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject ==  bytes32("VOTING_WINDOW"));
        require(uint256(proposalRegistry[proposalId].effect[0]) >= votingWindow / 4 && uint256(proposalRegistry[proposalId].effect[0]) <= assemblyInterval);


        votingWindow = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setBalances(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("BALANCES"));
        totalSupply_ = totalSupply_.sub(uint256(proposalRegistry[proposalId].effect[0]));
        balances[address(proposalRegistry[proposalId].effect[1])] = balances[address(proposalRegistry[proposalId].effect[1])].sub(uint256(proposalRegistry[proposalId].effect[0]));
    }

    function setEtherPermission(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("ETHER_PERMISSION"));
        require(proposalRegistry[proposalId].effect[0] == bytes32(0) || proposalRegistry[proposalId].effect[0] == bytes32(1));
        if(proposalRegistry[proposalId].effect[0] == bytes32(0)) {
            etherAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].isAllowed = false;
        } else {
            etherAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].isAllowed = true;
        }
    }

    function setEtherBudget(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("ETHER_BUDGET"));
        etherAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].budget = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setEtherPeriod(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("ETHER_PERIOD"));
        etherAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].budgetPeriod = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setTokenPermission(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("TOKEN_PERMISSION"));
        require(proposalRegistry[proposalId].effect[0] == bytes32(0) || proposalRegistry[proposalId].effect[0] == bytes32(1));
        if(proposalRegistry[proposalId].effect[0] == bytes32(0)) {
            tokenAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].isAllowed = false;
        } else {
            tokenAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].isAllowed = true;
        }
    }

    function setTokenBudget(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("TOKEN_BUDGET"));
        tokenAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].budget = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setTokenPeriod(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("TOKEN_PERIOD"));
        tokenAllowanceRegistry[address(proposalRegistry[proposalId].effect[1])].budgetPeriod = uint256(proposalRegistry[proposalId].effect[0]);
    }

    function setGoals(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("GOALS"));
        statutaryGoalsHash = proposalRegistry[proposalId].effect[0];
    }

    function setRules(bytes32 proposalId)
        public
        whenNotUpgraded
        mustBeAccepted(proposalId)
        afterApplicableVote(proposalId)
    {
        require(proposalRegistry[proposalId].subject == bytes32("RULES"));
        statutaryRulesHash = proposalRegistry[proposalId].effect[0];
    }

    /**
     * @dev reverts when plain value is being send to the contract. Sponsors should use the payTribute function in the SponsorRegistry contract.
     * @notice this callback function does not prevent the contract from receiving value at all. We have the possibilities selfdescruct or mining to the contract address.
     */
    function () payable {
        revert();
    }
}
