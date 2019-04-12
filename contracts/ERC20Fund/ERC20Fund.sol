import "./../votingEngine/VotingEngineHelpers.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.5.7;

//TODO: make the constructor into an array
// TODO: make a forwarder as well, to be able to specify another ERC20Treasury, but prevent ether from being lost when the old address is used.
contract ERC20Fund {

    mapping(address => bool) allowedAddresses;

    constructor(address initialERC20Treasury) {
        allowedAddresses[initialERC20Treasury] = true;
    }

    function transferERC20(address _ERC20, address to, uint256 amount) {
        require(allowedAddresses[msg.sender]);
        // Handing over control to an external contract. Possibility for re-entrancy.
        // No danger since:
        // * Communicty has voted for the allowance of an unsafeERC20
        // * If re-entrance: all what is achieved is depleting the allowance for the sender, without actually sending any ERC20.
        ERC20(_ERC20).transfer(to, amount);
    }
}
