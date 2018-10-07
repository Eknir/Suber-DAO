pragma solidity ^0.4.24;
// TODO: make a function which returns the etherAllowance struct for an address

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title EtherTreasury
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The Ether treasury registers who can spend funds and according to which parameters
 */
contract EtherTreasury {

    using SafeMath for uint256;

    mapping(address => etherAllowance) etherAllowanceRegistry;

    struct etherAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budget;
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
    function spend(address to, uint256 amount) public {
        require(amount <= address(this).balance);
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
        require(etherAllowanceRegistry[msg.sender].isAllowed);
        require(etherAllowanceRegistry[msg.sender].whenUpdated.add(etherAllowanceRegistry[msg.sender].budgetPeriod) <= now);
        require(etherAllowanceRegistry[msg.sender].allowance <= 4 * etherAllowanceRegistry[msg.sender].budget);
        etherAllowanceRegistry[msg.sender].whenUpdated = now;
        etherAllowanceRegistry[msg.sender].allowance += etherAllowanceRegistry[msg.sender].budget;
        emit EtherAllowanceIncreased(msg.sender, etherAllowanceRegistry[msg.sender].allowance);
    }
}
