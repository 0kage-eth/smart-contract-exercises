// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract TimeLock {
    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Cancel(bytes32 indexed txId);

    uint public constant MIN_DELAY = 10; // seconds
    uint public constant MAX_DELAY = 1000; // seconds
    uint public constant GRACE_PERIOD = 1000; // seconds

    address public owner;
    // tx id => queued
    mapping(bytes32 => bool) public queued;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "owner not sender");
        _;
    }

    receive() external payable {}

    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }

    /**
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send.
     * @param _timestamp Timestamp after which the transaction can be executed.
     */
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) onlyOwner external returns (bytes32 txId) {
        // code
        txId = getTxId(_target, _value, _func, _data, _timestamp);
       require(!queued[txId], "transaction already queued");
       require(_timestamp >= block.timestamp + MIN_DELAY && _timestamp <= block.timestamp + MAX_DELAY, "invalid time window") ;

       queued[txId] = true;
       emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }

    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) onlyOwner external payable returns (bytes memory) {
        // code
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp);
        require(queued[txId], "transaction not queued for execution");
        require(block.timestamp >= _timestamp && block.timestamp <= _timestamp + GRACE_PERIOD, "invalid time window for execution");

        delete queued[txId];

        // check if func is empty
        if(bytes(_func).length > 0){

            (bool success, bytes memory result) = _target.call{value: _value}(abi.encode(bytes4(keccak256(bytes(_func))), _data));
            require(success, "execution failed");
            emit Execute(txId, _target, _value, _func, _data, _timestamp);
            return result;
        }
        return "";
    }

    function cancel(bytes32 _txId) onlyOwner external {
        // code
        require(queued[_txId], "transaction not queued for execution");
         delete queued[_txId];
         emit Cancel(_txId);
    }
}

contract TestTimeLock {
    address public timeLock;
    bool public canExecute;
    bool public executed;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }

    fallback() external {}

    function func() external payable {
        require(msg.sender == timeLock, "not time lock");
        require(canExecute, "cannot execute this function");
        executed = true;
    }

    function setCanExecute(bool _canExecute) external {
        canExecute = _canExecute;
    }
}