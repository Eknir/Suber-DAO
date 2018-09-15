//TODO: Different kind of slashings for different kind of situations
//TODO: we now slash all voters, but perhaps we can slash those who propose a non-accepted votes as well?
//TODO: we need different degrees of slashing, since now we take away all voting rights in one slash => not good :(

pragma solidity ^0.4.24;

import "./VotingEngine.sol";

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Slasher
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev the Slasher allows for anybody to slash participants. The goal of this contract is to nudge participants of the DAO to vote in accordance with the rules and objectives.
 */
contract Slasher is VotingEngine {

    using SafeMath for uint256;

    event Slashed(
        address indexed callee,
        address indexed poorGuy,
        uint256 amount
    );

    /**
    * @dev can be called by anybody to slash a person if this person deserves slashing
    * @param poorGuy The address which will be slashed
    * @param proposalId the identifier of the vote to which the poorguy casted a 'wrong' vote
    * @param poorGuyVote the non-blinded vote of the poorGuy
    * @param poorGuyBlindedVote the blinded vote of the poorGuy
    * @param poorGuySecret the secret which was used by the poorGuy to shield his blindedVote from the public
    */
    function slash(address poorGuy, bytes32 proposalId, bool poorGuyVote, bytes32 poorGuyBlindedVote, bytes32 poorGuySecret ) {
        require(keccak256(abi.encodePacked(poorGuyVote, poorGuySecret)) == poorGuyBlindedVote);
        if(poorGuyVote) {
            require(proposalRegistry[proposalId].status == ProposalStatus.ProposalRejected);
            decreaseBalance(poorGuy, vouchersOf(poorGuy));
            emit Slashed(msg.sender, poorGuy, vouchersOf(poorGuy));
        } else {
            require(proposalRegistry[proposalId].status == ProposalStatus.Accepted);
            decreaseBalance(poorGuy, vouchersOf(poorGuy));
            emit Slashed(msg.sender, poorGuy, vouchersOf(poorGuy));


        }
    }

}
