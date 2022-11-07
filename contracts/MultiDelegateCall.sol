// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @notice We can run this contract to run multiple calls in a single function
 * @dev input data for calls is sent via bytes array
 * @dev output data is again a bytes arrsay of results -> each element is an output for specific functions
 */
contract MultiDelegatecall {
    function multiDelegatecall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results)
    {
        // declare results and assign it bytes
        results = new bytes[] (data.length);

        // code here
        for(uint i; i< data.length; i++){
           (bool success, bytes memory result) = address(this).delegatecall(data[i]);
           require(success, "call failed");
           results[i] = result;
        }
    }
}

contract TestMultiDelegatecall is MultiDelegatecall {
    event Log(address caller, string func, uint i);

    function func1(uint x, uint y) external {
        emit Log(msg.sender, "func1", x + y);
    }

    function func2() external returns (uint) {
        emit Log(msg.sender, "func2", 2);
        return 111;
    }
    
    function multiCall() external payable returns(bytes[] memory ){

        bytes memory hash1 = abi.encodeWithSignature("func1(uint256,uint256)", 5, 6);
        bytes memory hash2 = abi.encodeWithSignature("func2()", 35);

        bytes[] memory data = new bytes[](2);
        data[0] = hash1;
        data[1] = hash2;

        return data;
    }
    
}