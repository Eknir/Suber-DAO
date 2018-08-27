pragma solidity ^0.4.24;

import "./Upgradable.sol";

/**
 * @title SponsorRegistry
 * @author Rinke Hendriksen (rinkehendriksen@gmail.com)
 * @dev interested people can commit funds to the DAO via the SponsorRegistry. Afterwards, they will be able to produce a signature from the sponsorAddress, to make public their support to the cause of the DAO
 */
contract SponsorRegistry is Upgradable {

    event sponsorShipReceived(address indexed callee, uint256 amount);

    /**
     * @dev sponsors can use this function to grant funds to the DAO
     * @notice this is not the only way how funds can be given to the DAO. We have the possibilities selfdescruct or mining to the contract address
     */
    function payTribute() public payable whenNotUpgraded {
        require(msg.value > 0);
        emit sponsorShipReceived(msg.sender, msg.value);
    }
}
