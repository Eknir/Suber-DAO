// TODO: allow for setting the saveMultiplier
pragma solidity ^0.4.24;

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title EtherTreasury
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The Ether treasury registers who can spend funds and according to which parameters
 */
contract EtherTreasury {

    using SafeMath for uint256;

    mapping(address => etherAllowance) public etherAllowanceRegistry;

    struct EtherAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budget;
        uint256 saveMultiplier;
        uint256 budgetPeriod;
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


    /**
     * @dev can be called by an address with permission to spend to transfer Ether out of the DAO
     * @param to The address to which the Ether of the DAO will go.
     * @param amount The amount of Ethers which will be transferred.
     */
    function spendEther(address to, uint256 amount) public {
        require(to != address(0));
        require(amount <= etherAllowanceRegistry[msg.sender].allowance);
        etherAllowanceRegistry[msg.sender].allowance -= amount;
        to.transfer(amount);
        emit EtherSpent(msg.sender, to, amount);
    }

    /**
     * @dev can be called by an address with permission to spend to top-up their periodic allowance
     */
    function increaseEtherAllowance() {
        uint256 memory budget = etherAllowanceRegistry[msg.sender].budget;
        uint256 memory saveMultiplier = etherAllowanceRegistry[msg.sender].saveMultiplier;
        uint256 memory allowance = etherAllowanceRegistry[msg.sender].allowance;

        require(etherAllowanceRegistry[msg.sender].isAllowed);
        require(etherAllowanceRegistry[msg.sender].whenUpdated + etherAllowanceRegistry[msg.sender].budgetPeriod <= now);
        if(allowance + budget >= budget.mul(saveMultiplier)) {
            etherAllowanceRegistry[msg.sender].allowance = budget.mul(saveMultiplier); // maximum budget allowed
        } else {
            etherAllowanceRegistry[msg.sender].allowance = allowance.add(budget);
        }
        etherAllowanceRegistry[msg.sender].whenUpdated = now;
        emit EtherAllowanceIncreased(msg.sender, etherAllowanceRegistry[msg.sender].allowance);
    }
}
