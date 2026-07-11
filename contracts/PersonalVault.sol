// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PersonalVault {
    address public owner;
    uint256 public unlockTime;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);

    // Modifier untuk membatasi akses hanya bagi pemilik kontrak (Owner)
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Constructor memvalidasi bahwa _unlockTime wajib di masa depan
    constructor(uint256 _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // Fungsi receive untuk menerima Ether langsung
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Fungsi deposit manual
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit Deposit(msg.sender, msg.value);
    }

    // Fungsi withdraw lengkap dengan pengecekan waktu dan hak akses
    function withdraw() external onlyOwner {
        require(block.timestamp >= unlockTime, "Vault is still locked");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Mentransfer seluruh isi saldo vault ke owner
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdraw(owner, balance);
    }

    // Helper untuk mengecek sisa waktu penguncian
    function getRemainingTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }
}
