// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice HODL contract locks all withdrawals until a specific time
 * @dev this contract teaches how to use block.timestamp and lock time
 * @dev to freeze token transfers for a specific period
 */
contract Hodl {
    uint private constant HODL_DURATION = 3 * 365 days;

    mapping(address => uint) public balanceOf;
    mapping(address => uint) public lockedUntil;
    bool private locked;
    
    function deposit() external payable {
        // update balanceOf
        balanceOf[msg.sender] += msg.value;

        // update lockedUntil
        lockedUntil[msg.sender] = block.timestamp + HODL_DURATION;
    }
    
    modifier lock() {
        require(!locked, "locked");
        locked = true;
        _;
        locked = false;
    }

    function withdraw() external lock {
        require(block.timestamp >= lockedUntil[msg.sender], "cannot withdraw until hodl duration completes");
        uint256 balance = balanceOf[msg.sender];
        delete balanceOf[msg.sender];
        delete lockedUntil[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: balance }("");
        require(success, "withdraw failed");
    }
}