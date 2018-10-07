// TODO: make sure it is not possible to 'save' voucher allowance

pragma solidity ^0.4.24;

import "./VoucherRegistry.sol";

/**
 * @title TokenTreasury
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The token treasury registers who can mind voting tokens and according to which parameters
 */
contract VoucherTreasury is VoucherRegistry {

    mapping(address => voucherAllowance) public voucherAllowanceRegistry;

    struct voucherAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budgetPeriod;
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
        require(voucherAllowanceRegistry[msg.sender].isAllowed);
        require(voucherAllowanceRegistry[msg.sender].whenUpdated + voucherAllowanceRegistry[msg.sender].budgetPeriod <= now);
        voucherAllowanceRegistry[msg.sender].whenUpdated = now;
        voucherAllowanceRegistry[msg.sender].allowance = voucherAllowanceRegistry[msg.sender].allowance.add(voucherAllowanceRegistry[msg.sender].budget);
        emit TokenAllowanceIncreased(msg.sender, voucherAllowanceRegistry[msg.sender].allowance);
    }

    /**
    * @dev returns the tokenAllowance for a given address
    */
    function returnsVoucherAllowance(address allowed) public returns(voucherAllowance) {
        return voucherAllowanceRegistry[allowed];
    }
}
