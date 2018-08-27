pragma solidity ^0.4.24;

/**
 * @title Upgradable
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev keeps track of whether the contract is in a upgraded state and includes modifiers to adjust the behavior of the DAO accordingly
 */
contract Upgradable {

    bool public isUpgraded;
    uint256 public whenClosed;

    /**
     * @dev reverts when in the upgraded state
     */
    modifier whenNotUpgraded {
        require(!isUpgraded);
        _;
    }

    /**
     * @dev reverts when in the upgraded state and empty
     */
    modifier whenNotUpgradedAndNotEmpty {
        require(!(isUpgraded && whenClosed <= now));
        _;
    }
}
