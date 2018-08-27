// TODO: add natspec documentation
// TODO: make the whole acceptance / reveal / votingWindow thing dependent on enums, which can be set by the community via a seperate function (1)
// TODO: check cancelVote logic, since there might be an overlap in slashing / bringing votes in effect / cancelling them (2)
// TODO: implement cancelAcceptance (4)
//TODO: check for overflow (5)

pragma solidity ^0.4.24;

import "./TokenRegistry.sol";

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract VotingEngine is TokenRegistry {

    using SafeMath for uint256;

    event AssemblyDeclared(
        address indexed callee
    );
    event VoteProposed(
        address indexed callee,
        bytes32 indexed voteId
    );
    event AcceptanceSignalled(
        address indexed callee,
        bytes32 indexed voteId
    );
    event VoteAccepted(
        address indexed callee,
        bytes32 indexed voteId
    );
    event Voted(
        address indexed callee,
        bytes32 indexed voteId,
        bytes32 blindedVote
    );
    event VoteRevealed(
        address indexed callee,
        bytes32 indexed voteId,
        bool indexed vote,
        bytes32 secret,
        uint256 amountOfTokens
    );
    event VoteCancelled(
        address indexed callee,
        bytes32 indexed voteId
    );

    uint256 public referendumQuotum = 200000; // 20% (1,000,000 = 100%)
    uint256 public majorityQuotum = 600000; // 60%
    uint256 public assemblyPeriod = 1576800; // 6 months
    uint256 public votingWindow = 172800; // 2 days
    uint256 public lastAssembly;
    bytes32 emptyStringHash;

    struct ballot {
        bytes32 blindedVote;
        //TODO: see 1
        bool cancelled;
        bool used;
    }

    struct votes {
        mapping(address => ballot) blindedVoteRegistry;
        uint256 tokensInFavor;
        uint256 tokensAgainst;
        bytes32 subject;
        //TODO see 1
        bool accepted;
        bool inEffect;
        uint256 closingTime;
        bytes32[] effect;
    }

    struct referendumAcceptance {
        uint256 tokensInFavor;
        mapping(address => bool) signalled;
        uint256 closingTime;
    }

    mapping(address => uint256) public lastProposed;
    mapping(bytes32 => votes) public voteRegistry;
    mapping(bytes32 => referendumAcceptance) public acceptanceRegistry;
    mapping(bytes32 => bool) public blindedVoteUsed;


    constructor(uint256 _lastVote) {
        lastAssembly = _lastVote;
        emptyStringHash = keccak256(abi.encodePacked(""));

    }

    function declareAssembly() {
        require(lastAssembly.add(assemblyPeriod) >= now);
        lastAssembly = now;
        emit AssemblyDeclared(msg.sender);
    }

    function proposeReferendum(bytes32 voteId, bytes32 _subject, bytes32[1] _effect) {
        require(_subject != bytes32(""));
        require(voteRegistry[voteId].subject == bytes32(""));
        voteRegistry[voteId].subject == _subject;
        voteRegistry[voteId].effect = _effect;
        if(lastAssembly.add(votingWindow) >= now) {
            // during assembly we don't want anyone to spam the organisation with votes which have to be considered
            require(balanceOf(msg.sender) != 0);
            require(lastProposed[msg.sender].add(votingWindow) <= now);
            lastProposed[msg.sender] == now;
            voteRegistry[voteId].accepted = true;
            voteRegistry[voteId].closingTime = now.add(votingWindow);
            emit VoteAccepted(msg.sender, voteId);
        } else {
            acceptanceRegistry[voteId].closingTime = now.add(votingWindow);
            emit VoteProposed(msg.sender, voteId);
        }

    }

    function signalAcceptance(bytes32 voteId) {
        require(voteRegistry[voteId].subject != bytes32(""));
        require(!voteRegistry[voteId].accepted);
        require(acceptanceRegistry[voteId].closingTime <= now);
        require(!acceptanceRegistry[voteId].signalled[msg.sender]);
        acceptanceRegistry[voteId].signalled[msg.sender] == true;
        acceptanceRegistry[voteId].tokensInFavor.add(balanceOf(msg.sender));
        emit AcceptanceSignalled(msg.sender, voteId);
    }

    function cancelAcceptance(bytes32 voteId) {
        //TODO, see 3
    }

    function makeAccepted(bytes32 voteId) {
        require(!voteRegistry[voteId].accepted);
        //TODO, see 5
        require((acceptanceRegistry[voteId].tokensInFavor * 1000000) / totalSupply()  >= referendumQuotum);
        voteRegistry[voteId].accepted = true;
        voteRegistry[voteId].closingTime = now.add(votingWindow / 2);
        emit VoteAccepted(msg.sender, voteId);
    }

    function vote(bytes32 voteId, bytes32 blindedVote) {
        require(!blindedVoteUsed[blindedVote]);
        require(keccak256(abi.encodePacked(voteRegistry[voteId].subject)) != emptyStringHash);
        require(voteRegistry[voteId].accepted);
        require(voteRegistry[voteId].blindedVoteRegistry[msg.sender].blindedVote == bytes32(0));
        require(voteRegistry[voteId].closingTime >= now);
        voteRegistry[voteId].blindedVoteRegistry[msg.sender].blindedVote = blindedVote;
        blindedVoteUsed[blindedVote] = true;
        emit Voted(msg.sender, voteId, blindedVote);
    }

    function revealVote(bytes32 voteId, bytes32 secret, bool myVote) {
        //TODO, see 1
        require(voteRegistry[voteId].closingTime >= now && voteRegistry[voteId].closingTime.add(votingWindow) <= now);
        require(keccak256(abi.encodePacked(myVote,secret)) == voteRegistry[voteId].blindedVoteRegistry[msg.sender].blindedVote);
        require(!voteRegistry[voteId].blindedVoteRegistry[msg.sender].cancelled);
        require(!voteRegistry[voteId].blindedVoteRegistry[msg.sender].used);
        voteRegistry[voteId].blindedVoteRegistry[msg.sender].used = true;
        if(myVote) {
            voteRegistry[voteId].tokensInFavor.add(balanceOf(msg.sender));
        } else {
            voteRegistry[voteId].tokensAgainst.add(balanceOf(msg.sender));
        }
        emit VoteRevealed(msg.sender, voteId, myVote, secret, balanceOf(msg.sender));
    }

    function cancelVote(bytes32 voteId, bytes32 secret, bool myVote) {
        //TODO, see 2
        require(voteRegistry[voteId].closingTime >= now && voteRegistry[voteId].closingTime.add(votingWindow) <= now);
        require(keccak256(abi.encodePacked(myVote,secret)) == voteRegistry[voteId].blindedVoteRegistry[msg.sender].blindedVote);
        require(!voteRegistry[voteId].blindedVoteRegistry[msg.sender].cancelled);
        require(voteRegistry[voteId].blindedVoteRegistry[msg.sender].used);
        voteRegistry[voteId].blindedVoteRegistry[msg.sender].cancelled = true;
        if(myVote) {
            voteRegistry[voteId].tokensInFavor.sub(balanceOf(msg.sender));
        } else {
            voteRegistry[voteId].tokensAgainst.sub(balanceOf(msg.sender));
        }
        emit VoteCancelled(msg.sender, voteId);
    }
}
