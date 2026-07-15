// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PersonalVault {
    // ========= Custom Errors =========
    error FundsLocked();
    error NotOwner();
    error InvalidUnlockTime();

    // ========= State =========
    address public owner;
    uint256 public unlockTime;

    // ========= Events =========
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(uint256 amount, uint256 timestamp);
    event LockExtended(uint256 newUnlockTime);

    // ========= Modifier =========
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // ========= Constructor =========
    constructor(uint256 _unlockTime) payable {
        if (_unlockTime <= block.timestamp) {
            revert InvalidUnlockTime();
        }

        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // ========= Deposit =========
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Optional: menerima ETH langsung
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // ========= Extend Lock =========
    function extendLock(uint256 newTime) external onlyOwner {
        if (newTime <= unlockTime) {
            revert InvalidUnlockTime();
        }

        unlockTime = newTime;

        emit LockExtended(newTime);
    }

    // ========= Withdraw =========
    function withdraw() external onlyOwner {
        if (block.timestamp < unlockTime) {
            revert FundsLocked();
        }

        uint256 amount = address(this).balance;

        require(amount > 0, "No balance");

        (bool success, ) = payable(owner).call{value: amount}("");

        require(success, "Transfer failed");

        emit Withdrawal(amount, block.timestamp);
    }
}
