//TODO: get rid of the multiplication with 100000 (
// TODO: set tokensInFavor / tokensAgainst default to 1 ++ tokensInFavor / tokensAgainst is not equal to 60% of total voted tokens.
// TODO: Emit the closing time as well in the ProposalStatusChanged
// TODO: Get rid of the status inEffect and let instead all the seperate modules keep track of wether they have incorporated the change.

import "./../voucherRegistry/VoucherRegistry.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

pragma solidity ^0.4.24;

/**
 * @title VotingEngine
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev the VotingEngine contract makes sure proposals can be proposed and passed if there exists enough support from the community
 */
contract VotingEngine {

    using SafeMath for uint256;

    event AssemblyDeclared(
        address indexed callee
    );

    event ProposalStatusChanged(
        address indexed callee,
        bytes32 indexed proposalId,
        ProposalStatus newStatus
    );

    event ReferendumProposed(
        address indexed callee,
        bytes32 indexed proposalId
    );

    event ProposalProposed(
        address indexed callee,
        bytes32 indexed proposalId
    );

    event AcceptanceSignalled(
        address indexed callee,
        bytes32 indexed proposalId
    );

    event BallotCommitted(
        address indexed callee,
        bytes32 indexed proposalId,
        bytes32 blindedVote
    );

    event BallotRevealed(
        address indexed callee,
        bytes32 indexed proposalId,
        bool vote,
        bytes32 secret,
        uint256 amountOfVouchers
    );
    event BallotCancelled(
        address indexed callee,
        bytes32 indexed proposalId,
        bool vote,
        bytes32 secret,
        uint256 amountOfVouchers
    );

    VoucherRegistry voucherRegistry;
    uint256 public referendumQuotum;
    uint256 public majorityQuotum;
    uint256 public assemblyInterval;
    uint256 public assemblyDuration;
    uint256 public votingWindow;
    uint256 public revealOrCancelWindow;
    uint256 public minimumVouchersToPropose;

    uint256 public lastAssembly = 0; // after deployment an assembly can be declared directly // TODO: allow for setting lastAssembly during deployment?


    // Used in the votes struct to keep track of ballot status per address
    enum BallotStatus {
        // Default status for a ballot
        NotUsed,

        // When used in the referendum
        Signalled,

        // When cancelled in the referendum
        SignalCancelled,

        // When ballot is revealed
        BallotRevealed,

        // When ballot is cancelled
        BallotCancelled
    }

    struct ballot {
        bytes32 blindedVote;
        BallotStatus status;
    }

    enum ProposalStatus {
        // INITIAL STAGE. Any possible proposalId is Default.
        Default,

        /**
        * When there is no assembly, a proposal has to pass the referendum stage to be considered by the community.
        */
        Referendum,

        /**
        * After passing the referendum stage or during assembly, ballots must be committed. If not committed and/or revealed
        * there will be a slash.
        */
        Commit,

        /**
        * After commitment, ballots must be revealed. The choice to use a commit/reveal pattern is that it is necesarry
        * for the game-mechanics that all community members vote independently of each others votes. It is possible to cancel
        * a ballot (making it non-effective) to prevent one entity to be able to buy votes (and be sure it will never be cancelled).
        */
        RevealOrCancel,

        /**
        * FINAL STAGE. Accepted proposals can be used by the master contract to enact the change on which was voted
        */
        Accepted,

        /**
        * FINAL STAGE. If after the revealOrCancel stage has passed there has not been a majorityQuotum votes in favor of the proposal
        * the proposal ends up in the ProposalRejected stage.
        */
        ProposalRejected,

        /**
        * FINAL STAGE. If votingWindow time has passed since initialization of the Referendum stage, and the referendum has
        * not achieved enough support, it ends up in the ReferendumRejected stage.
        */
        ReferendumRejected
    }

    // used in the mapping proposalRegistry; Every proposalId maps to one proposal structy
    struct proposal {
        address proposer;
        mapping(address => ballot) ballotRegistry;
        uint256 tokensInFavor;
        uint256 tokensAgainst;
        bytes32 subject; // subject is read by the master contract and defines how the proposal is being acted upon after acceptance
        ProposalStatus status; // before a proposal
        uint256 closingTime; // during different phases, we assign a closingTime to mark the end of the phase
        bytes32[] effect; // the intended effect(s) of the proposal. i.e. budget (uint) per period for a specified entity (address)
    }

    mapping(address => uint256) public lastProposed; // we keep track of when an address last-proposed a vote in order to prevent spamming of the assembly
    mapping(bytes32 => proposal) public proposalRegistry;
    mapping(bytes32 => bool) public blindedVoteUsed; // we keep track of the blindedVotes used to prevent the possibility of secret re-use

  //  referendumQuotum = 200000; // 20% (1,000,000 = 100%)
  //  majorityQuotum = 600000; // 60%
  //  assemblyInterval = 1576800; // 6 months
  //  assemblyDuration = 122800; // 2 days TODO, see 6
  //  votingWindow = 172800; // 2 days
  //  revealOrCancelWindow = 86400; // 1 day
  //  minimumVouchersToPropose = 0; // a treshhold which is needed to propose a vote during the assembly
    constructor(
        uint256 _referendumQuotum,
        uint256 _majorityQuotum,
        uint256 _assemblyInterval,
        uint256 _assemblyDuration,
        uint256 _votingWindow,
        uint256 _revealOrCancelWindow,
        uint256 _minimumVouchersToPropose,
        address _voucherRegistry
    ) {
        referendumQuotum = _referendumQuotum;
        majorityQuotum = _majorityQuotum;
        assemblyInterval = _assemblyInterval;
        assemblyDuration = _assemblyDuration;
        votingWindow = _votingWindow;
        revealOrCancelWindow = _revealOrCancelWindow;
        minimumVouchersToPropose = _minimumVouchersToPropose;
        voucherRegistry = VoucherRegistry(_voucherRegistry);
    }

    /**
    * @dev can be called by anybody once every assemblyPeriod and will activate the assembly
    */
    function declareAssembly() public {
        require(lastAssembly.add(assemblyInterval) >= now); // only possible to declare one assembly per assemblyInterval
        lastAssembly = now;
        emit AssemblyDeclared(msg.sender);
    }

    /**
    * @dev can be called by anybody if the assembly is not active to create a referendum
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    * @param _subject the topic of the proposal (used in the master contract for interpretation of the effect)
    * @param _effect the proposed effect of the proposal
    */
    function makeFromDefaultToReferendum(bytes32 proposalId, bytes32 _subject, bytes32[1] _effect) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Default);
        require(lastAssembly.add(assemblyInterval) <= now);
        proposalRegistry[proposalId].proposer = msg.sender;
        proposalRegistry[proposalId].status = ProposalStatus.Referendum;
        proposalRegistry[proposalId].closingTime = now.add(votingWindow);
        proposalRegistry[proposalId].subject == _subject;
        proposalRegistry[proposalId].effect = _effect;
        emit ReferendumProposed(msg.sender, proposalId);
    }

    /**
    * @dev can be called by anybody if the votingWindow has passed after starting the refendum and there has not been referendumQuotum support for the proposal
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    */
    function makeFromReferendumToRejected(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Referendum);
        require(proposalRegistry[proposalId].closingTime <= now);
        proposalRegistry[proposalId].status = ProposalStatus.ReferendumRejected;
        emit ProposalStatusChanged(msg.sender, proposalId, ProposalStatus.ReferendumRejected);
    }

    /**
    * @dev can be called by anybody if the assembly is active to create a proposal which directly enters the commit stage and must be considered by the members
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    * @param _subject the topic of the proposal (used in the master contract for interpretation of the effect)
    * @param _effect the proposed effect of the proposal
    * @notice every member can only propose one proposal every assemblyperiod to prevent too many votes which must be taken into consideration
    */
    function makeFromDefaultToCommit(bytes32 proposalId, bytes32 _subject, bytes32[1] _effect) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Default);
        require(lastAssembly.add(assemblyInterval) >= now);
        require(voucherRegistry.vouchersOf(msg.sender) > minimumVouchersToPropose);
        require(lastProposed[msg.sender].add(votingWindow) <= now);
        lastProposed[msg.sender] = now;
        proposalRegistry[proposalId].proposer = msg.sender;
        proposalRegistry[proposalId].status = ProposalStatus.Commit;
        proposalRegistry[proposalId].closingTime = now.add(votingWindow);
        proposalRegistry[proposalId].subject == _subject;
        proposalRegistry[proposalId].effect = _effect;
        emit ProposalProposed(msg.sender, proposalId);
    }

    /**
    * @dev used by the members of the dao to signal support for the referendum (and hence request this refendum to enter the commit stage)
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    */
    function ballotSignal(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Referendum);
        require(proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.NotUsed);
        proposalRegistry[proposalId].ballotRegistry[msg.sender].status = BallotStatus.Signalled;
        proposalRegistry[proposalId].tokensInFavor.add(voucherRegistry.vouchersOf(msg.sender));
        emit AcceptanceSignalled(msg.sender, proposalId);
    }

    /**
    * @dev used by the members of the dao to cancel their support for the referendum
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    * @notice this function is effectively an anti-bribery function, since vouchers are non-transferable and because of this function
    * purchasing private keys with vouchers is also useless since it is never possible to purchase a key and be entirely sure that the original
    * holder did not save the key somewhere else and use this function to make the signal (or ballot) of the purchaser ineffective
    */
    function cancelSignal(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Referendum);
        require(proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.Signalled);
        proposalRegistry[proposalId].tokensInFavor.sub(voucherRegistry.vouchersOf(msg.sender));
        proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.SignalCancelled;
    }

    /**
    * @dev if there is enough support for the proposal within the votingWindow timeframe, the proposal will enter the commit stage
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    */
    function makeFromReferendumToCommit(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Referendum);
        //TODO: see 10
        assert(proposalRegistry[proposalId].tokensInFavor * 1000000 >= proposalRegistry[proposalId].tokensInFavor);
        require((proposalRegistry[proposalId].tokensInFavor * 1000000) / voucherRegistry.getTotalVouchers() >= referendumQuotum); // we multiply by 1000000 to implement decimal points calculation
        proposalRegistry[proposalId].tokensInFavor = 0;
        proposalRegistry[proposalId].status = ProposalStatus.Commit;
        proposalRegistry[proposalId].closingTime = now.add(votingWindow);
        emit ProposalStatusChanged(msg.sender, proposalId, ProposalStatus.Commit);
    }

    /**
    * @dev if a proposal is in the commit stage, a blindedVote must be committed.
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    * @param blindedVote the hash of the vote + password
    * @notice if a member does not commit (and reveal afterwards) a vote on a proposal which is in this stage, he will be slashed
    * @notice the commit-reveal pattern is needed to ensure that every member decides autonomously what to vote
    */
    function ballotCommit(bytes32 proposalId, bytes32 blindedVote) {
        require(!blindedVoteUsed[blindedVote]);
        require(proposalRegistry[proposalId].status == ProposalStatus.Commit);
        require(
            proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.NotUsed ||
            proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.Signalled ||
            proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.SignalCancelled
        );
        proposalRegistry[proposalId].ballotRegistry[msg.sender].blindedVote = blindedVote;
        blindedVoteUsed[blindedVote] = true;
        emit BallotCommitted(msg.sender, proposalId, blindedVote);
    }

    /**
    * @dev after passing of votingWindow time since the start of the commit phase, any member can set the proposal to the next (revealOrCancel) phase
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    * @notice besides the regular revealing, in the revealOrCancel stage, it is also possible to cancel a previously commited (or revealed) ballot
    */
    function makeFromCommitToRevealOrCancel(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.Commit);
        require(proposalRegistry[proposalId].closingTime <= now);
        proposalRegistry[proposalId].closingTime = now + revealOrCancelWindow;
        proposalRegistry[proposalId].status = ProposalStatus.RevealOrCancel;
        emit ProposalStatusChanged(msg.sender, proposalId, ProposalStatus.RevealOrCancel);
    }

    /**
    * @dev if a proposal is in the reveal stage, the previously committed blindedVote must be revealed
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    * @param secret the previously used secret to hide the vote in the ballotCommit function
    * @param myVote the vote (true/false)
    * @notice secret and myVote must hash to the committed blindedVote
    * @notice if a member does not commit (and reveal afterwards) a vote on a proposal which is in this stage, he will be slashed
    * @notice the commit-reveal pattern is needed to ensure that every member decides autonomously what to vote
    */
    function ballotReveal(bytes32 proposalId, bytes32 secret, bool myVote) {
        require(proposalRegistry[proposalId].status == ProposalStatus.RevealOrCancel);
        require(keccak256(abi.encodePacked(myVote,secret)) == proposalRegistry[proposalId].ballotRegistry[msg.sender].blindedVote);
        require(
            proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.NotUsed ||
            proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.Signalled ||
            proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.SignalCancelled
        );
        proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.BallotRevealed;
        if(myVote) {
            proposalRegistry[proposalId].tokensInFavor.add(voucherRegistry.vouchersOf(msg.sender));
        } else {
            proposalRegistry[proposalId].tokensAgainst.add(voucherRegistry.vouchersOf(msg.sender));
        }
        emit BallotRevealed(msg.sender, proposalId, myVote, secret, voucherRegistry.vouchersOf(msg.sender));
    }

    /**
    * @dev after revealOrCancelWindow time has passed since the proposal entered the revealOrCancelWindow and there has be a majorityQuotum of votes or more in favor of the proposal
    * any member can call this function to make the proposal accepted (hence allow the master contract to make the vote into effect)
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    */
    function makeFromRevealOrCancelToAccepted(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.RevealOrCancel);
        require(proposalRegistry[proposalId].closingTime <= now);
        require(((proposalRegistry[proposalId].tokensInFavor / proposalRegistry[proposalId].tokensAgainst) * 1000000) >= majorityQuotum); // TODO: see 5,
        proposalRegistry[proposalId].status == ProposalStatus.Accepted;
        proposalRegistry[proposalId].closingTime = now;
        emit ProposalStatusChanged(msg.sender, proposalId, ProposalStatus.Accepted);
    }

    /**
    * @dev after revealOrCancelWindow time has passed since the proposal entered the revealOrCancelWindow and there has be a majorityQuotum of votes or more in favor of the proposal
    * any member can call this function to make the proposal accepted (hence allow the master contract to make the vote into effect)
    * @param proposalId the unique identifier of the proposal. Can be anything if not used before
    */
    function makeFromRevealOrCancelToRejected(bytes32 proposalId) {
        require(proposalRegistry[proposalId].status == ProposalStatus.RevealOrCancel);
        require(proposalRegistry[proposalId].closingTime <= now);
        require(((proposalRegistry[proposalId].tokensInFavor / proposalRegistry[proposalId].tokensAgainst) * 1000000) < majorityQuotum); // TODO: see 5,
        proposalRegistry[proposalId].status == ProposalStatus.ProposalRejected;
        proposalRegistry[proposalId].closingTime = now;
        emit ProposalStatusChanged(msg.sender, proposalId, ProposalStatus.ProposalRejected);
    }

    /**
    * @dev used by the members of the dao to cancel their ballot commit or ballot reveal for the proposal
    * @param secret the previously used secret to hide the vote in the ballotCommit function
    * @param myVote the vote (true/false)
    * @notice this function is effectively an anti-bribery function, since vouchers are non-transferable and because of this function
    * purchasing private keys with vouchers is also useless since it is never possible to purchase a key and be entirely sure that the original
    * holder did not save the key somewhere else and use this function to make the signal (or ballot) of the purchaser ineffective
    */
    function cancelBallot(bytes32 proposalId, bytes32 secret, bool myVote) {
        require(proposalRegistry[proposalId].status == ProposalStatus.RevealOrCancel);
        require(keccak256(abi.encodePacked(myVote,secret)) == proposalRegistry[proposalId].ballotRegistry[msg.sender].blindedVote);
        require(proposalRegistry[proposalId].ballotRegistry[msg.sender].status != BallotStatus.BallotCancelled);
        proposalRegistry[proposalId].ballotRegistry[msg.sender].status == BallotStatus.BallotCancelled;
        if(myVote) {
            proposalRegistry[proposalId].tokensInFavor.sub(voucherRegistry.vouchersOf(msg.sender));
        } else {
            proposalRegistry[proposalId].tokensAgainst.sub(voucherRegistry.vouchersOf(msg.sender));
        }
        emit BallotCancelled(msg.sender, proposalId, myVote, secret, voucherRegistry.vouchersOf(msg.sender));
    }

    function getProposalProposer(bytes32 proposalId) view returns(address) {
        return proposalRegistry[proposalId].proposer;
    }

    function getBallotStatus(bytes32 proposalId, address voter) view returns(BallotStatus) {
        return proposalRegistry[proposalId].ballotRegistry[voter].status;
    }

    function getBallotBlindedVote(bytes32 proposalId, address voter) view returns(bytes32) {
        return proposalRegistry[proposalId].ballotRegistry[voter].blindedVote;
    }

    function getProposalSubject(bytes32 proposalId) view returns(bytes32) {
        return proposalRegistry[proposalId].subject;
    }

    function getProposalStatus(bytes32 proposalId) view returns(ProposalStatus) {
        return proposalRegistry[proposalId].status;
    }

    function getProposalClosingTime(bytes32 proposalId) view returns(uint256) {
        return proposalRegistry[proposalId].closingTime;
    }

    function getProposalEffectZero(bytes32 proposalId) view returns(bytes32) {
        return proposalRegistry[proposalId].effect[0];
    }

    function getProposalEffectOne(bytes32 proposalId) view returns(bytes32) {
        return proposalRegistry[proposalId].effect[1];
    }

    function getProposalEffectTwo(bytes32 proposalId) view returns(bytes32) {
        return proposalRegistry[proposalId].effect[2];
    }

    function getProposalEffectThree(bytes32 proposalId) view returns(bytes32) {
        return proposalRegistry[proposalId].effect[3];
    }
}
