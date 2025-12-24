// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

// custom errors
error ZeroAmount();
error InsufficientBalance();
error WithdrawFailed();
error OnlyOwner();

contract SimpleBank {
    address public owner;
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event OwnerWithdrawn(uint256 amount);
    event Transfered(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert OnlyOwner();
        _;
    }

    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();

        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        uint256 curBalance = balances[msg.sender];
        if (amount > curBalance) revert InsufficientBalance();

        balances[msg.sender] = curBalance - amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawFailed();

        emit Withdrawn(msg.sender, amount);
    }

    //tranfer
    function transfer(address to, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        address from = msg.sender;

        uint256 curBalance = balances[from];
        if (amount > curBalance) revert InsufficientBalance();

        balances[from] = curBalance - amount;
        balances[to] += amount;

        emit Transfered(to, amount);
    }

    // owner withdraw
    function ownerWithdraw(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();

        uint256 bankBalance = address(this).balance;
        if (amount > bankBalance) revert InsufficientBalance();

        (bool success,) = payable(owner).call{value: amount}("");
        if (!success) revert WithdrawFailed();

        emit OwnerWithdrawn(amount);
    }

    function totalBankBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
