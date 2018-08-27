pragma solidity ^0.4.24;

import "./TokenRegistry.sol";

/**
 * @title TokenTreasury
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The token treasury registers who can mind voting tokens and according to which parameters
 */
contract TokenTreasury is TokenRegistry {

    mapping(address => tokenAllowance) public tokenAllowanceRegistry;

    struct tokenAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budgetPeriod;
        uint256 budget;
    }

    event TokenAllowanceIncreased(
        address indexed callee,
        uint256 newAllowance
    );
    event Minted(
        address indexed callee,
        address indexed to,
        uint256 amount
    );


    /**
    * @dev can be called by an address with permission to mint voting tokens
    * @param to The address to which the voting tokens will go.
    * @param amount The amount of voting tokens which will be transferred.
    * @notice the internal function mint resides in the TokenRegistry contract
    */
    function mint(address to, uint256 amount) public {
        require(to != address(0));
        require(amount <= tokenAllowanceRegistry[msg.sender].allowance);
        tokenAllowanceRegistry[msg.sender].allowance -= amount;
        mint_(to, amount);
        emit Minted(msg.sender, to, amount);

    }

    /**
    * @dev can be called by an address with permission to mint to top-up the periodic allowance
    */
    function increaseTokenAllowance() {
        require(tokenAllowanceRegistry[msg.sender].isAllowed);
        require(tokenAllowanceRegistry[msg.sender].whenUpdated + tokenAllowanceRegistry[msg.sender].budgetPeriod <= now);
        tokenAllowanceRegistry[msg.sender].whenUpdated = now;
        tokenAllowanceRegistry[msg.sender].allowance = tokenAllowanceRegistry[msg.sender].allowance.add(tokenAllowanceRegistry[msg.sender].budget);
        emit TokenAllowanceIncreased(msg.sender, tokenAllowanceRegistry[msg.sender].allowance);
    }
}
