// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title Governance
 * @dev Contract to handle governance and upgrades.
 */
contract Governance {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }

    // Placeholder for additional governance logic
}
