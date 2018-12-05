import "./../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./../etherFund/EtherFund.sol";

pragma solidity ^0.4.24;

/**
 * @title EtherTreasury
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The Ether treasury registers who can spend funds and according to which parameters
 */
contract EtherTreasury {

    using SafeMath for uint256;

    mapping(address => EtherAllowance) public etherAllowanceRegistry;
    mapping(address => bool) public trustedEtherFund;

    struct EtherAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budget;
        uint256 saveMultiplier;
        uint256 period;
    }

    event EtherAllowanceIncreased(
        address indexed callee,
        uint256 newAllowance
    );
    event EtherSpent(
        address indexed callee,
        address indexed to,
        uint256 amount
    );

    constructor(
        address[] initialSpenders,
        uint[] initialSpendBudgets,
        uint[] initialSpendBudgetPeriods,
        uint[] initialSpendMultipliers,
        address initialEtherFund
    ) {
        uint256 numberOfSpenders = initialSpenders.length;
        require(
            initialSpendBudgets.length == numberOfSpenders &&
            initialSpendBudgetPeriods.length == numberOfSpenders &&
            initialSpendMultipliers.length == numberOfSpenders
        );
        for(uint256 i = 0; i <= numberOfSpenders; i++) {
            etherAllowanceRegistry[initialSpenders[i]].budget = initialSpendBudgets[i];
            etherAllowanceRegistry[initialSpenders[i]].period = initialSpendBudgetPeriods[i];
            etherAllowanceRegistry[initialSpenders[i]].saveMultiplier = initialSpendMultipliers[i];
        }
        trustedEtherFund[initialEtherFund] = true;
    }


    /**
     * @dev can be called by an address with permission to spend to transfer Ether out of the DAO
     * @param to The address to which the Ether of the DAO will go.
     * @param amount The amount of Ethers which will be transferred.
     */
    function spendEther(address etherFund, address to, uint256 amount) public {
        require(to != address(0));
        require(trustedEtherFund[etherFund]);
        require(amount <= etherAllowanceRegistry[msg.sender].allowance);
        etherAllowanceRegistry[msg.sender].allowance -= amount;
        emit EtherSpent(msg.sender, to, amount);
        EtherFund(etherFund).withdraw(to, amount);
    }

    /**
     * @dev can be called by an address with permission to spend to top-up their periodic allowance
     */
    function increaseEtherAllowance() {
        uint256 budget = etherAllowanceRegistry[msg.sender].budget;
        uint256 saveMultiplier = etherAllowanceRegistry[msg.sender].saveMultiplier;
        uint256 allowance = etherAllowanceRegistry[msg.sender].allowance;

        require(etherAllowanceRegistry[msg.sender].isAllowed);
        require(etherAllowanceRegistry[msg.sender].whenUpdated + etherAllowanceRegistry[msg.sender].period <= now);
        if(allowance + budget >= budget.mul(saveMultiplier)) {
            etherAllowanceRegistry[msg.sender].allowance = budget.mul(saveMultiplier); // maximum budget allowed
        } else {
            etherAllowanceRegistry[msg.sender].allowance = allowance.add(budget);
        }
        etherAllowanceRegistry[msg.sender].whenUpdated = now;
        emit EtherAllowanceIncreased(msg.sender, etherAllowanceRegistry[msg.sender].allowance);
    }
}
