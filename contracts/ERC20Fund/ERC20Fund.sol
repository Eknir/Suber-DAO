import "./../votingEngine/VotingEngineHelpers.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.4.24;

//TODO: make the constructor into an array
// TODO: make a forwarder as well, to be able to specify another ERC20Treasury, but prevent ether from being lost when the old address is used.
contract ERC20Fund {

    mapping(address => bool) allowedAddresses;

    constructor(address initialERC20Treasury) {
        allowedAddresses[initialERC20Treasury] = true;
    }

    function transferERC20(address _ERC20, address to, uint256 amount) {
        require(allowedAddresses[msg.sender]);
        ERC20(_ERC20).transfer(to, amount);
    }
}
