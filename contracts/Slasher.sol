// TODO: Allow the different slashes to be changed via the master contract

pragma solidity ^0.4.24;

import "./VotingEngine.sol";

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Slasher
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev the Slasher allows for anybody to slash participants. The goal of this contract is to nudge participants of the DAO to vote in accordance with the rules and objectives.
 */
contract Slasher is VotingEngine {

    uint256 proposerSlash = 20;
    uint256 voterSlash = 2;
    uint256 nonVoterSlash = 5;


    using SafeMath for uint256;

    event VoterSlashed(
        address indexed callee,
        address indexed voter,
        uint256 vouchersTaken
    );

    event ProposerSlashed(
        address indexed callee,
        address indexed proposer,
        uint256 vouchersTaken
    );

    event NonVoterSlashed(
        address indexed callee,
        address indexed nonVoter,
        uint256 vouchersTaken
    );
    
    /**
    * @dev can be called by anybody to slash a proposer who proposed a vote which did not get accepted
    */
    function slashProposer(bytes32 proposalId) {
        require(
            proposalRegistry[proposalId].status == ProposalStatus.ProposalRejected ||
            proposalRegistry[proposalId].status == ProposalStatus.ReferendumRejected
        );
        address memory proposer = proposalRegistry[proposalId].proposer;
        uint256 memory initialVouchers = vouchersOf(proposer);
        uint256 memory toBeSlashed = (initialVouchers * proposerSlash) / 100;
        assert((toBeSlashed * 100) / proposerSlash == initialVouchers);
        decreaseBalance(proposer, toBeSlashed);
    }

    function slashVoter(
        address voter,
        bytes32 proposalId,
        bool vote,
        bytes32 blindedVote,
        bytes32 secret
    ) {
        require(keccak256(abi.encodePacked(vote, secret)) == blindedVote);
            if(vote) {
                require(proposalRegistry[proposalId].status == ProposalStatus.ProposalRejected);
            } else {
                require(proposalRegistry[proposalId].status == ProposalStatus.Accepted);
            }
        uint256 memory initialVouchers = vouchersOf(voter);
        uint256 memory toBeSlashed = (initialVouchers * voterSlash) / 100;
        assert((toBeSlashed * 100) / voterSlash == initialVouchers);
        decreaseBalance(voter, toBeSlashed);
        emit VoterSlashed(msg.sender, voter, toBeSlashed);
    }   
  
    function slashNotVoted(
        address voter,
        bytes32 proposalId
    ) {
        require(
            proposalRegistry[proposalId].status == ProposalStatus.Accepted || 
            proposalRegistry[proposalId].status == ProposalStatus.ProposalRejected
        );
        require(proposalRegistry[proposalId].ballotRegistry[voter].status != BallotStatus.BallotRevealed);
        uint256 memory initialVouchers = vouchersOf(voter);
        uint256 memory toBeSlashed = (initialVouchers * nonVoterSlash) / 100;
        assert((toBeSlashed * 100) / nonVoterSlash == initialVouchers);
        decreaseBalance(voter, toBeSlashed);
    }
}
