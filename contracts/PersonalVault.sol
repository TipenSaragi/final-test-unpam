// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLockedVault {
    address public owner;
    uint256 public unlockTime;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);

    // Modifier untuk membatasi akses hanya untuk owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Hanya pemilik yang dapat memanggil fungsi ini");
        _;
    }

    // Constructor memvalidasi bahwa _unlockTime harus di masa depan
    constructor(uint256 _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Waktu buka kunci harus di masa depan");
        
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // Fungsi untuk menerima deposit Ether
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Fungsi deposit manual
    function deposit() external payable {
        require(msg.value > 0, "Jumlah deposit harus lebih dari 0");
        emit Deposit(msg.sender, msg.value);
    }

    // Fungsi withdraw dengan validasi waktu dan pemegang hak
    function withdraw() external onlyOwner {
        require(block.timestamp >= unlockTime, "Vault masih terkunci");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "Tidak ada saldo untuk ditarik");

        // Mentransfer saldo ke owner
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Gagal mengirim Ether");

        emit Withdraw(owner, balance);
    }

    // Fungsi helper untuk mengecek sisa waktu terkunci
    function getRemaingTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }
}
