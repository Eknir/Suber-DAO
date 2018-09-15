pragma solidity ^0.4.24;

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title TokenRegistry
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev keeps track of the amount of voting tokens belonging to addresses and allows to modify these amounts
 */
contract VoucherRegistry {

    using SafeMath for uint256;

    uint256 internal totalSupply_;
    mapping(address => uint256) internal balances;

    function vouchersOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev function can be called by the Slasher contract and substracts voting tokens from an address for a certain amount
     */
    function decreaseBalance(address poorGuy, uint256 amount) internal returns (bool) {
        require(amount <= balances[poorGuy]);
        balances[poorGuy] += balances[poorGuy].sub(amount);
    }

    /**
     * @dev function can be called by the TokenTreasury contract and adds voting tokens to an address for a certain amount
     */
    function mint_(address to, uint256 amount) internal returns (bool) {
        balances[to].add(amount);
        totalSupply_ = totalSupply_.add(amount);
    }
}
