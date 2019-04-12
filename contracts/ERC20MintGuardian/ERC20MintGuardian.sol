import "./../votingEngine/VotingEngineHelpers.sol";

import "./../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


pragma solidity ^0.5.7;

contract ERC20MintGuardian is VotingEngineHelpers {

    using SafeMath for uint256;

    mapping(address => mapping(address => ERC20MintingAllowance)) public ERC20MintingAllowanceRegistry;


    struct ERC20MintingAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budget;
        uint256 saveMultiplier;
        uint256 period;
    }

    event ERC20MintingAllowanceIncreased(
        address indexed callee,
        address indexed ERC20,
        uint256 newAllowance
    );

    event ERC20Minted(
        address indexed callee,
        address indexed ERC20,
        address indexed to,
        uint256 amount
    );

    constructor(
        address initialERC20Mint,
        address[] initialMinters,
        uint[] initialMintBudgets,
        uint[] initialMintPeriods,
        uint[] initialMintSaveMultipliers,
        address votingEngine
    ) VotingEngineHelpers(
        votingEngine
    ) {
        uint256 numberOfMinters = initialMinters.length;
        require(
            initialMintBudgets.length == numberOfMinters &&
            initialMintPeriods.length == numberOfMinters &&
            initialMintSaveMultipliers.length == numberOfMinters
        );
        for(uint256 i = 0; i <= numberOfMinters; i++) {
            ERC20MintingAllowanceRegistry[initialMinters[i]][initialERC20Mint].budget = initialMintBudgets[i];
            ERC20MintingAllowanceRegistry[initialMinters[i]][initialERC20Mint].period = initialMintPeriods[i];
            ERC20MintingAllowanceRegistry[initialMinters[i]][initialERC20Mint].saveMultiplier = initialMintSaveMultipliers[i];
        }
    }

    function mintERC20(address to, address _ERC20Mintable, uint256 amount) public returns(bool success) {
        require(amount <= ERC20MintingAllowanceRegistry[msg.sender][_ERC20Mintable].allowance);
        require(to != address(0));
        ERC20Mintable unsafeMint = ERC20Mintable(_ERC20Mintable);
        //TODO! unsafe -= !!! potential for integer underflow!
        ERC20MintingAllowanceRegistry[msg.sender][_ERC20Mintable].allowance -= amount;
        // Handing over control to an external contract. Possibility for re-entrancy.
        // No danger since:
        // * Communicty has voted for the allowance of an unsafeERC20
        // * If re-entrance: all what is achieved is depleting the allowance for the sender, without actually sending any ERC20.
        unsafeMint.mint(to, amount);
        emit ERC20Minted(msg.sender, _ERC20Mintable, to, amount);
    }

    function increaseERC20MintAllowance(address ERC20Mintable) {
        uint256 budget = ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].budget;
        uint256 saveMultiplier = ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].saveMultiplier;
        uint256 allowance = ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance;
        require(ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].isAllowed);
        require(ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].whenUpdated +
              ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].period <= now);
        if(allowance + budget >= budget.mul(saveMultiplier)) {
              ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance = budget.mul(saveMultiplier); // maximum budget allowed
        } else {
            ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance = allowance.add(budget);
        }
        ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].whenUpdated = now;
        emit ERC20MintingAllowanceIncreased(
            msg.sender,
            ERC20Mintable,
            ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance
        );
    }

    function addMinter(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == bytes32("AddERC20Minter"));
        // ERC20Mintable is potentially unsafe. We have to watch out for re-entrancy here, but since we already
        // set the status to InEffect in the constructor, there is no possibility for re-entering this contract.
        // furthermore, we assume that the community would only vote for AddMinter with an effectOne that would actually not cause re-entrancy
        ERC20Mintable(address(votingEngine.getProposalEffectOne(proposalId))).addMinter(
            address(votingEngine.getProposalEffectZero(proposalId))
        );
    }

    function renounceMinter(bytes32 proposalId)
        public
        applicableVote(proposalId)
    {
        require(votingEngine.getProposalSubject(proposalId) == bytes32("RenounceERC20Minter"));
        // ERC20Mintable is potentially unsafe. We have to watch out for re-entrancy here, but since we already
        // set the status to InEffect in the constructor, there is no possibility for re-entering this contract.
        // furthermore, we assume that the community would only vote for AddMinter with an effectOne that would actually not cause re-entrancy
        ERC20Mintable(address(votingEngine.getProposalEffectOne(proposalId))).renounceMinter();
    }
}
