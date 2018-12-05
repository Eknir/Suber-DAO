import "./../votingEngine/VotingEngineHelpers.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

//TODO: make a structure as the etherfund also for the ERC20Treasury 
pragma solidity ^0.4.24;

contract ERC20Treasury is VotingEngineHelpers {
    using SafeMath for uint256;

    mapping(address => mapping(address => ERC20SpendingAllowance)) public ERC20SpendingAllowanceRegistry;

    struct ERC20SpendingAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budget;
        uint256 saveMultiplier;
        uint256 period;
    }

    event ERC20SpendingAllowanceIncreased(
        address indexed callee,
        address indexed ERC20,
        uint256 newAllowance
    );

    event ERC20Spent(
        address indexed callee,
        address indexed ERC20,
        address indexed to,
        uint256 amount
    );

    constructor(
        address[] initialSpenders,
        address[] initialERC20s,
        uint[] initialSpendBudgets,
        uint[] initialSpendBudgetPeriods,
        uint[] initialSpendMultipliers,
        address votingEngine
    ) VotingEngineHelpers(
        votingEngine
    ) {
        //TODO: initialize all initial things (see voucherMintGuardian for an example)
    }

    /**
     * @dev TODO
     */
    function spendERC20(address to, address _ERC20, uint256 amount) public returns(bool success) {
        require(amount <= ERC20SpendingAllowanceRegistry[msg.sender][_ERC20].allowance);
        require(to != address(0));
        ERC20 unsafeToken = ERC20(_ERC20);
        ERC20SpendingAllowanceRegistry[msg.sender][_ERC20].allowance -= amount;
        // Handing over control to an external contract. Possibility for re-entrancy.
        // No danger since:
        // * Communicty has voted for the allowance of an unsafeERC20
        // * If re-entrance: all what is achieved is depleting the allowance for the sender, without actually sending any ERC20.
        unsafeToken.transfer(to, amount);
        emit ERC20Spent(msg.sender, _ERC20, to, amount);
        return true;
    }

    function increaseERC20SpendAllowance(address ERC20) {
        uint256 budget = ERC20SpendingAllowanceRegistry[msg.sender][ERC20].budget;
        uint256 saveMultiplier = ERC20SpendingAllowanceRegistry[msg.sender][ERC20].saveMultiplier;
        uint256 allowance = ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance;

        require(ERC20SpendingAllowanceRegistry[msg.sender][ERC20].isAllowed);
        require(ERC20SpendingAllowanceRegistry[msg.sender][ERC20].whenUpdated +
            ERC20SpendingAllowanceRegistry[msg.sender][ERC20].period <= now
        );
        if(allowance + budget >= budget.mul(saveMultiplier)) {
            ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance = budget.mul(saveMultiplier); // maximum budget allowed
        } else {
            ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance = allowance.add(budget);
        }
        ERC20SpendingAllowanceRegistry[msg.sender][ERC20].whenUpdated = now;
        emit ERC20SpendingAllowanceIncreased(msg.sender, ERC20, ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance);
    }
}
