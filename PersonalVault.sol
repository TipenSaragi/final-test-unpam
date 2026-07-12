// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PersonalVault {

    // Custom Errors (lebih hemat gas daripada require dengan string)
    error FundsLocked();
    error NotOwner();
    error InvalidUnlockTime();

    address public owner;
    uint256 public unlockTime;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);
    event LockExtended(uint256 newUnlockTime);

    // Modifier supaya hanya owner yang bisa menjalankan fungsi tertentu
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // Saat deploy contract, waktu unlock harus lebih besar dari waktu sekarang
    constructor(uint256 _unlockTime) payable {
        if (_unlockTime <= block.timestamp) {
            revert InvalidUnlockTime();
        }

        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // Bisa menerima ETH langsung tanpa memanggil function deposit()
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Function untuk menyimpan ETH ke dalam vault
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        emit Deposit(msg.sender, msg.value);
    }

    // Owner bisa memperpanjang waktu penguncian
    // Waktu baru wajib lebih lama dari waktu yang sekarang
    function extendLock(uint256 _newUnlockTime) external onlyOwner {
        if (_newUnlockTime <= unlockTime) {
            revert InvalidUnlockTime();
        }

        unlockTime = _newUnlockTime;

        emit LockExtended(_newUnlockTime);
    }

    // Setelah waktu habis, owner bisa mengambil seluruh saldo
    function withdraw() external onlyOwner {

        if (block.timestamp < unlockTime) {
            revert FundsLocked();
        }

        uint256 balance = address(this).balance;

        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner).call{value: balance}("");

        require(success, "Transfer failed");

        emit Withdraw(owner, balance);
    }

    // Melihat sisa waktu sampai vault terbuka
    function getRemainingTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) {
            return 0;
        }

        return unlockTime - block.timestamp;
    }
}
