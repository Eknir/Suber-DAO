pragma solidity ^0.4.24;

//TODO: allow for ownership change of ERC20-mint

import "./../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";

contract ERC20Registry.sol {
    using safeMath for uint256;

    mapping(address => ERC20Mintable);
    mapping(address => mapping(address => ERC20SpendingAllowance)) public ERC20SpendingAllowanceRegistry;
    mapping(address => mapping(address => ERC20MintingAllowance)) public ERC20MintingAllowanceRegistry;

    struct ERC20SpendingAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budget;
        uint256 saveMultiplier;
        uint256 budgetPeriod;
    }

    struct ERC20MintingAllowance {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 budget;
        uint256 saveMultiplier;
        uint256 budgetPeriod;
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
        uint256 memory budget = ERC20SpendingAllowanceRegistry[msg.sender][ERC20].budget;
        uint256 memory saveMultiplier = ERC20SpendingAllowanceRegistry[msg.sender][ERC20].saveMultiplier;
        uint256 memory allowance = ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance;

        require(ERC20SpendingAllowanceRegistry[msg.sender][ERC20].isAllowed);
        require(ERC20SpendingAllowanceRegistry[msg.sender][ERC20].whenUpdated + ERC20SpendingAllowanceRegistry[msg.sender][ERC20].budgetPeriod <= now);
        if(allowance + budget >= budget.mul(saveMultiplier)) {
            ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance = budget.mul(saveMultiplier); // maximum budget allowed
        } else {
            ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance = allowance.add(budget);
        }
        ERC20SpendingAllowanceRegistry[msg.sender][ERC20].whenUpdated = now;
        emit ERC20SpendingAllowanceIncreased(msg.sender, ERC20, ERC20SpendingAllowanceRegistry[msg.sender][ERC20].allowance);
    }

    function mintERC20(address to, address _ERC20Mintable, uint256 amount) public returns(bool success) {
        require(amount <= ERC20MintingAllowanceRegistry[msg.sender][_ERC20Mintable].allowance);
        require(to != address(0));
        ERC20 unsafeMint = ERC20Mintable(_ERC20Mintable);
        ERC20MintingAllowanceRegistry[msg.sender][_ERC20].allowance -= amount;
        // Handing over control to an external contract. Possibility for re-entrancy.
        // No danger since:
        // * Communicty has voted for the allowance of an unsafeERC20
        // * If re-entrance: all what is achieved is depleting the allowance for the sender, without actually sending any ERC20.
        unsafeMint.mint(to, amount);
        emit ERC20Minted(msg.sender, _ERC20Mintable, to, amount);
    }

    function increaseERC20MintAllowance(address ERC20Mintable) {
        uint256 memory budget = ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].budget;
        uint256 memory saveMultiplier = ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].saveMultiplier;
        uint256 memory allowance = ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance;

        require(ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].isAllowed);
        require(ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].whenUpdated + ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].budgetPeriod <= now);
        if(allowance + budget >= budget.mul(saveMultiplier)) {
            ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance = budget.mul(saveMultiplier); // maximum budget allowed
        } else {
            ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance = allowance.add(budget);
        }
        ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].whenUpdated = now;
        emit ERC20MintingAllowanceIncreased(msg.sender, ERC20Mintable, ERC20MintingAllowanceRegistry[msg.sender][ERC20Mintable].allowance);
    }
}
