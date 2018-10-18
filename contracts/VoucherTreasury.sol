// TODO: allow for setting the saveMultiplier

pragma solidity ^0.4.24;

import "./VoucherRegistry.sol";

/**
 * @title TokenTreasury
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The token treasury registers who can mind voting tokens and according to which parameters
 */
contract VoucherTreasury is VoucherRegistry {

    mapping(address => VoucherAllowance) public voucherAllowanceRegistry;

    struct VoucherAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budgetPeriod;
        uint256 saveMultiplier;
        uint256 budget;
    }

    event voucherAllowanceIncreased(
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
        require(amount <= voucherAllowanceRegistry[msg.sender].allowance);
        voucherAllowanceRegistry[msg.sender].allowance -= amount;
        mint_(to, amount);
        emit Minted(msg.sender, to, amount);

    }

    /**
    * @dev can be called by an address with permission to mint to top-up the periodic allowance
    */
    function increaseVoucherAllowance() {
        uint256 memory budget = voucherAllowanceRegistry[msg.sender].budget;
        uint256 memory saveMultiplier = voucherAllowanceRegistry[msg.sender].saveMultiplier;
        uint256 memory allowance = voucherAllowanceRegistry[msg.sender].allowance;
        require(voucherAllowanceRegistry[msg.sender].isAllowed);
        require(voucherAllowanceRegistry[msg.sender].whenUpdated + voucherAllowanceRegistry[msg.sender].budgetPeriod <= now);
        if(allowance + budget >= budget * saveMultiplier) {
            voucherAllowanceRegistry[msg.sender].allowance = budget * saveMultiplier;
        } else {
            voucherAllowanceRegistry[msg.sender].allowance = allowance.add(budget);
        }
        voucherAllowanceRegistry[msg.sender].whenUpdated = now;
        emit TokenAllowanceIncreased(msg.sender, voucherAllowanceRegistry[msg.sender].allowance);
    }
}
