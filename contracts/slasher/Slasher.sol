import "./../votingEngine/VotingEngine.sol";
import "./../voucherRegistry/VoucherRegistry.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

pragma solidity ^0.4.24;

/**
 * @title Slasher
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev the Slasher allows for anybody to slash participants. The goal of this contract is to nudge participants of the DAO to vote in accordance with the rules and objectives.
 */
contract Slasher {

    using SafeMath for uint256;

    VoucherRegistry voucherRegistry;
    VotingEngine votingEngine;
    uint8 proposerSlash;
    uint8 voterSlash;
    uint8 nonVoterSlash;
    uint256 slasherWindow;

    struct Slashed {
        bool voterSlashed;
        bool proposerSlashed;
    }

    mapping(bytes32 => mapping(address => Slashed)) public slashRegistry;

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

    constructor(
        uint8 _proposerSlash,
        uint8 _voterSlash,
        uint8 _nonVoterSlash,
        uint256 _slasherWindow,
        address _voucherRegistry
    ) {
        voucherRegistry = VoucherRegistry(_voucherRegistry);
        proposerSlash = _proposerSlash;
        voterSlash = _voterSlash;
        nonVoterSlash = _nonVoterSlash;
        slasherWindow = _slasherWindow;
    }

    /**
    * @dev can be called by anybody to slash a proposer who proposed a vote which did not get accepted
    */
    function slashProposer(bytes32 proposalId) {
        VotingEngine.ProposalStatus status = votingEngine.getProposalStatus(proposalId);
        require(
            status == VotingEngine.ProposalStatus.ProposalRejected ||
            status == VotingEngine.ProposalStatus.ReferendumRejected
        );
        require(votingEngine.getProposalClosingTime(proposalId) + slasherWindow <= now);
        address proposer = votingEngine.getProposalProposer(proposalId);
        require(!slashRegistry[proposalId][proposer].proposerSlashed);
        uint256 initialVouchers = voucherRegistry.vouchersOf(proposer);
        uint256 toBeSlashed = (initialVouchers * proposerSlash) / 100;
        assert((toBeSlashed * 100) / proposerSlash == initialVouchers); // integer overflow check
        slashRegistry[proposalId][proposer].proposerSlashed = true;
        if(toBeSlashed == 0) {
            voucherRegistry.decreaseBalance(proposer, proposerSlash);
        }
        voucherRegistry.decreaseBalance(proposer, toBeSlashed);
    }

    function slashVoter(
        address voter,
        bytes32 proposalId,
        bool vote,
        bytes32 blindedVote,
        bytes32 secret
    ) {
        require(votingEngine.getBallotStatus(proposalId, voter) == VotingEngine.BallotStatus.BallotRevealed);
        require(!slashRegistry[proposalId][voter].voterSlashed);
        require(keccak256(abi.encodePacked(vote, secret)) == blindedVote);
        require(votingEngine.getBallotBlindedVote(proposalId, voter) == blindedVote);
        require(votingEngine.getProposalClosingTime(proposalId) + slasherWindow <= now);
        if(vote) {
            require(votingEngine.getProposalStatus(proposalId) == VotingEngine.ProposalStatus.ProposalRejected);
        } else {
            VotingEngine.ProposalStatus status = votingEngine.getProposalStatus(proposalId);
            require(status == VotingEngine.ProposalStatus.Accepted);
        }
        uint256 initialVouchers = voucherRegistry.vouchersOf(voter);
        uint256 toBeSlashed = (initialVouchers * voterSlash) / 100; // integer overflow check
        assert((toBeSlashed * 100) / voterSlash == initialVouchers);
        slashRegistry[proposalId][voter].voterSlashed = true;
        if(toBeSlashed == 0) {
            voucherRegistry.decreaseBalance(voter, voterSlash);
        }
        //TODO: set the status to proposerSlashed
        voucherRegistry.decreaseBalance(voter, toBeSlashed);
        emit VoterSlashed(msg.sender, voter, toBeSlashed);
    }

    function slashNonVoter(
        bytes32 proposalId,
        address voter
    ) {
        VotingEngine.ProposalStatus status = votingEngine.getProposalStatus(proposalId);
        require(
            status == VotingEngine.ProposalStatus.ProposalRejected ||
            status == VotingEngine.ProposalStatus.Accepted
        );
        require(!slashRegistry[proposalId][voter].voterSlashed);
        require(votingEngine.getBallotStatus(proposalId, voter) != VotingEngine.BallotStatus.BallotRevealed);
        require(votingEngine.getProposalClosingTime(proposalId) + slasherWindow <= now);
        uint256 initialVouchers = voucherRegistry.vouchersOf(voter);
        uint256 toBeSlashed = (initialVouchers * nonVoterSlash) / 100;
        assert((toBeSlashed * 100) / nonVoterSlash == initialVouchers);
        slashRegistry[proposalId][voter].voterSlashed = true;
        if(toBeSlashed == 0) {
            voucherRegistry.decreaseBalance(voter, nonVoterSlash);
        }
        voucherRegistry.decreaseBalance(voter, toBeSlashed);
    }
}
