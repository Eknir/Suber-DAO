import "./../voucherRegistry/VoucherRegistry.sol";
import "./../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

pragma solidity ^0.4.24;

/**
 * @title TokenTreasury
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev The token treasury registers who can mind voting tokens and according to which parameters
 */
contract VoucherMintGuardian {

    using SafeMath for uint256;


    VoucherRegistry voucherRegistry;

    mapping(address => voucherMint) public voucherMintRegistry;

    struct voucherMint {
        bool isAllowed;
        uint256 allowance;
        uint256 whenUpdated;
        uint256 period;
        uint256 saveMultiplier;
        uint256 budget;
    }

    event voucherAllowanceIncreased(
        address indexed callee,
        uint256 newAllowance
    );
    event Minted(
        address indexed callee,
        address indexed to,
        uint256 amount
    );

    constructor(
        address[] initialMinters,
        uint256[] initialMintBudgets,
        uint256[] initialMintPeriods,
        uint256[] initialMintSaveMultipliers,
        address _voucherRegistry
    )
    {
        uint256 numberOfMinters = initialMinters.length;
        require(
            initialMintBudgets.length == numberOfMinters &&
            initialMintPeriods.length == numberOfMinters &&
            initialMintSaveMultipliers.length == numberOfMinters
        );
        for(uint256 i = 0; i <= numberOfMinters; i++) {
            voucherMintRegistry[initialMinters[i]].budget = initialMintBudgets[i];
            voucherMintRegistry[initialMinters[i]].period = initialMintPeriods[i];
            voucherMintRegistry[initialMinters[i]].saveMultiplier = initialMintSaveMultipliers[i];
        }
        voucherRegistry = VoucherRegistry(_voucherRegistry);
    }


    /**
    * @dev can be called by an address with permission to mint voting tokens
    * @param to The address to which the voting tokens will go.
    * @param amount The amount of voting tokens which will be transferred.
    * @notice the internal function mint resides in the TokenRegistry contract
    */
    function mint(address to, uint256 amount) public {
        require(to != address(0));
        require(amount <= voucherMintRegistry[msg.sender].allowance);
        voucherMintRegistry[msg.sender].allowance -= amount;
        voucherRegistry.mint(to, amount);
        emit Minted(msg.sender, to, amount);
    }

    /**
    * @dev can be called by an address with permission to mint to top-up the periodic allowance
    */
    function increaseVoucherAllowance() {
        uint256 budget = voucherMintRegistry[msg.sender].budget;
        uint256 saveMultiplier = voucherMintRegistry[msg.sender].saveMultiplier;
        uint256 allowance = voucherMintRegistry[msg.sender].allowance;
        require(voucherMintRegistry[msg.sender].isAllowed);
        require(voucherMintRegistry[msg.sender].whenUpdated + voucherMintRegistry[msg.sender].period <= now);
        if(allowance + budget >= budget * saveMultiplier) {
            voucherMintRegistry[msg.sender].allowance = budget * saveMultiplier;
        } else {
            voucherMintRegistry[msg.sender].allowance = allowance.add(budget);
        }
        voucherMintRegistry[msg.sender].whenUpdated = now;
        emit voucherAllowanceIncreased(msg.sender, voucherMintRegistry[msg.sender].allowance);
    }
}
