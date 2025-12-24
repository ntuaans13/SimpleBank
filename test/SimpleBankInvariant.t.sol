// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank internal bank;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event OwnerWithdrawn(uint256 amount);
    event Transfered(address indexed to, uint256 amount);

    address internal owner;
    address internal alice = address(0x1);
    address internal bob = address(0x2);

    function setUp() public {
        owner = address(this);
        bank = new SimpleBank();
    }

    //helper
    function _deposit(address sender, uint256 amount) internal {
        vm.deal(sender, amount);
        vm.prank(sender);
        bank.deposit{value: amount}();
    }

    function testInitialState() public {
        assertEq(bank.owner(), owner);
    }
}