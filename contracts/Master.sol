//TODO, implement overflow checks for multiplications (1)

pragma solidity ^0.4.24;

import "./TokenTreasury.sol";
import "./Slasher.sol";
import "./EtherTreasury.sol";
import "./SponsorRegistry.sol";

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Master
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The Master registers the hashes of the statutary goals and objectives of the DAO and makes sure all parameters can be updated when voted for
 */
contract Master is TokenTreasury, Slasher, EtherTreasury, SponsorRegistry {

    using SafeMath for uint256;

    bytes32 public statutaryGoalsHash;
    bytes32 public statutaryRulesHash;

    constructor(
        bytes32 _statutaryGoalsHash,
        bytes32 _statutaryRulesHash,
        uint256 lastVote
    )
        Slasher(lastVote)
    {
        statutaryGoalsHash = _statutaryGoalsHash;
        statutaryRulesHash = _statutaryRulesHash;
    }

    event logUpgraded(
        address indexed callee,
        bytes32 voteId
    );

    modifier beforeApplicableVote(bytes32 voteId) {
        require(!voteRegistry[voteId].inEffect);
        require((voteRegistry[voteId].closingTime.add(votingWindow)) < now);
        //TODO, see 1
        require(((voteRegistry[voteId].tokensInFavor / voteRegistry[voteId].tokensAgainst) * 1000000) >= majorityQuotum);
        _;
    }

    modifier afterApplicableVote(bytes32 voteId) {
      _;
      voteRegistry[voteId].inEffect = true;
      emit logUpgraded(msg.sender, voteId);
    }

    function setSuperUpgrade(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("SUPER_UPGRADE"));
        // TODO, see 1
        require(uint256(voteRegistry[voteId].effect[0]) <= (assemblyPeriod * 4));
        isUpgraded = true;
        whenClosed = uint256(voteRegistry[voteId].effect[0]);
    }

    function setReferendumQuotum(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("REFERENDUM_QUOTUM"));
        require(uint256(voteRegistry[voteId].effect[0]) <= 1000000); // 100%
        referendumQuotum = uint256(voteRegistry[voteId].effect[0]);
    }

    function setMajorityQuotum(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("MAJORITY_QUOTUM"));
        require(uint256(voteRegistry[voteId].effect[0]) <= 1000000); // 100%
        majorityQuotum = uint256(voteRegistry[voteId].effect[0]);
    }

    function setAssemblyPeriod(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("ASSEMBLY_PERIOD"));
        // TODO, see 1
        require(uint256(voteRegistry[voteId].effect[0]) >= assemblyPeriod / 4 && uint256(voteRegistry[voteId].effect[0]) <= (assemblyPeriod * 4));
        assemblyPeriod = uint256(voteRegistry[voteId].effect[0]);
    }

    function setVotingWindow(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject ==  bytes32("VOTING_WINDOW"));
        require(uint256(voteRegistry[voteId].effect[0]) >= votingWindow / 4 && uint256(voteRegistry[voteId].effect[0]) <= assemblyPeriod);


        votingWindow = uint256(voteRegistry[voteId].effect[0]);
    }

    function setBalances(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("BALANCES"));
        totalSupply_ = totalSupply_.sub(uint256(voteRegistry[voteId].effect[0]));
        balances[address(voteRegistry[voteId].effect[1])] = balances[address(voteRegistry[voteId].effect[1])].sub(uint256(voteRegistry[voteId].effect[0]));
    }

    function setEtherPermission(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("ETHER_PERMISSION"));
        require(voteRegistry[voteId].effect[0] == bytes32(0) || voteRegistry[voteId].effect[0] == bytes32(1));
        if(voteRegistry[voteId].effect[0] == bytes32(0)) {
            etherAllowanceRegistry[address(voteRegistry[voteId].effect[1])].isAllowed = false;
        } else {
            etherAllowanceRegistry[address(voteRegistry[voteId].effect[1])].isAllowed = true;
        }
    }

    function setEtherBudget(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("ETHER_BUDGET"));
        etherAllowanceRegistry[address(voteRegistry[voteId].effect[1])].budget = uint256(voteRegistry[voteId].effect[0]);
    }

    function setEtherPeriod(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("ETHER_PERIOD"));
        etherAllowanceRegistry[address(voteRegistry[voteId].effect[1])].budgetPeriod = uint256(voteRegistry[voteId].effect[0]);
    }

    function setTokenPermission(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("TOKEN_PERMISSION"));
        require(voteRegistry[voteId].effect[0] == bytes32(0) || voteRegistry[voteId].effect[0] == bytes32(1));
        if(voteRegistry[voteId].effect[0] == bytes32(0)) {
            tokenAllowanceRegistry[address(voteRegistry[voteId].effect[1])].isAllowed = false;
        } else {
            tokenAllowanceRegistry[address(voteRegistry[voteId].effect[1])].isAllowed = true;
        }
    }

    function setTokenBudget(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("TOKEN_BUDGET"));
        tokenAllowanceRegistry[address(voteRegistry[voteId].effect[1])].budget = uint256(voteRegistry[voteId].effect[0]);
    }

    function setTokenPeriod(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("TOKEN_PERIOD"));
        tokenAllowanceRegistry[address(voteRegistry[voteId].effect[1])].budgetPeriod = uint256(voteRegistry[voteId].effect[0]);
    }

    function setGoals(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("GOALS"));
        statutaryGoalsHash = voteRegistry[voteId].effect[0];
    }

    function setRules(bytes32 voteId)
        public
        whenNotUpgraded
        beforeApplicableVote(voteId)
        afterApplicableVote(voteId)
    {
        require(voteRegistry[voteId].subject == bytes32("RULES"));
        statutaryRulesHash = voteRegistry[voteId].effect[0];
    }

    /**
     * @dev reverts when plain value is being send to the contract. Sponsors should use the payTribute function in the SponsorRegistry contract.
     * @notice this callback function does not prevent the contract from receiving value at all. We have the possibilities selfdescruct or mining to the contract address.
     */
    function () payable {
        revert();
    }
}
