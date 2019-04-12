import "./../votingEngine/VotingEngineHelpers.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
//TODO: split allowedAddresses into allowedToMint and allowedToBurn

pragma solidity ^0.4.24;

/**
 * @title TokenRegistry
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev keeps track of the amount of voting tokens belonging to addresses and allows to modify these amounts
 */
contract VoucherRegistry {

    using SafeMath for uint256;

    uint256 internal totalVouchers;
    mapping(address => uint256) internal vouchers;

    function vouchersOf(address _owner) public view returns (uint256) {
        return vouchers[_owner];
    }

    function getTotalVouchers() public view returns (uint256) {
        return totalVouchers;
    }

    mapping(address => bool) allowedAddresses;

    constructor(
        address slasher,
        address voucherMintGuardian
    )
    {
        allowedAddresses[slasher] = true;
        allowedAddresses[voucherMintGuardian] = true;
    }

    /**
     * @dev function can be called by the Slasher contract and substracts voting tokens from an address for a certain amount
     */
    function decreaseBalance(address poorGuy, uint256 amount) public returns (bool) {
        require(allowedAddresses[msg.sender]);
        require(amount <= vouchersOf(poorGuy));
        vouchers[poorGuy] = vouchersOf(poorGuy).sub(amount);
        totalVouchers = getTotalVouchers().sub(amount);
    }

    /**
     * @dev function can be called by the VoucherTreasury contract and adds voting tokens to an address for a certain amount
     */
    function mint(address to, uint256 amount) public returns (bool) {
        require(allowedAddresses[msg.sender]);
        vouchers[to].add(amount);
        totalVouchers = getTotalVouchers().add(amount);
    }
}
