pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// @title SuberDAOVouchers
// @author eknir
// @dev the SuberDAOVouchers contract allows for pre-minting of voting vouchers, to be used in the Suber-Dao. The purpose is to ensure that
// the initial assignment of vouchers is widespread and among trusted people, while at the same time notifying about the Suber-Dao and incentivicing
// them to tell others about it.
contract SuberDAOVouchers is Ownable {

    event LogMinted(bytes32 passwordHash);
    event LogRedeemed(bytes32 password, address voucherOwner);
    event LogMultiplied(address voucherOwner, address friend);

    struct Voucher {
        bool minted;
        bool redeemed;
        bool multiplied;
    }

    mapping(bytes32 => Voucher) public voucherRegistry;
    mapping(address => bytes32) public hasVoucher;

    // @dev this function allows the owner of the contract to mint vouchers which are protected by a password
    // @notice reuse of passwords is not possible
    function mint(bytes32 passwordHash) public onlyOwner returns(bool success) {
        require(!voucherRegistry[passwordHash].minted);
        voucherRegistry[passwordHash].minted = true;
        emit LogMinted(passwordHash);
        return true;
    }

    // @dev allows anybody who knows a password to redeem the vouchers protected by this password to his address
    // @notice hasVoucher is set to the hash of the password for the msg.sender, which identifies that this person has been given a voucher by the owner of this contract
    function redeem(bytes32 password) public returns(bool success) {
        require(
            voucherRegistry[keccak256(abi.encodePacked(password))].minted &&
            !voucherRegistry[keccak256(abi.encodePacked(password))].redeemed &&
            hasVoucher[msg.sender] == bytes32(0)
        );
        voucherRegistry[keccak256(abi.encodePacked(password))].redeemed = true;
        hasVoucher[msg.sender] = keccak256(abi.encodePacked(password));
        emit LogRedeemed(password, msg.sender);
        return true;
    }

    // @dev anybody who was initially assigned a voucher can multiply his token by assigning a friend.
    // @notice hasVoucher is set to bytes32(1) for the friend, which identifies that the friend got his voucher not via the owner of this contract
    // @notice only those who got their vouchers via the owner of the contract can use this function
    function multiply(address friend) public returns(bool success) {
        require(
            voucherRegistry[hasVoucher[msg.sender]].redeemed &&
            !voucherRegistry[hasVoucher[msg.sender]].multiplied &&
            hasVoucher[friend] == bytes32(0)
        );
        voucherRegistry[hasVoucher[msg.sender]].multiplied = true;
        hasVoucher[friend] = bytes32(1);
        emit LogMultiplied(msg.sender, friend);
        return true;
    }
}
