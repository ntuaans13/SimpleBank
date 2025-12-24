// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleBank.sol";
import "forge-std/console.sol";

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

    // deposit
    function testDepositWorksAndEmitsEvent() public {
        uint256 amount = 1 ether;
        vm.deal(alice, amount);

        vm.expectEmit(true, false, false, true, address(bank));
        emit Deposited(alice, amount);

        vm.prank(alice);
        bank.deposit{value: amount}();

        assertEq(bank.balances(alice), amount);
        assertEq(address(bank).balance, amount);
    }

    function testDepositRevertsZeroAmount() public {
        vm.deal(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert(ZeroAmount.selector);
        bank.deposit{value: 0 ether}();
    }

    // withdraw
    function testWithdrawWorksAndEmitsEvent() public {
        uint256 amount = 1 ether;
        _deposit(alice, amount);

        assertEq(bank.balances(alice), amount);
        assertEq(address(bank).balance, amount);

        vm.expectEmit(true, false, false, true, address(bank));
        emit Withdrawn(alice, amount);

        vm.prank(alice);
        bank.withdraw(amount);

        assertEq(bank.balances(alice), 0);
        assertEq(address(bank).balance, 0);
        assertEq(alice.balance, amount);
    }

    function testWithdrawRevertsZeroAmount() public {
        _deposit(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert(ZeroAmount.selector);
        bank.withdraw(0);
    }

    function testWithdrawRevertInsufficientBalance() public {
        _deposit(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert(InsufficientBalance.selector);
        bank.withdraw(2 ether);
    }

    // transfer
    function testTransferWorksAndEmitEvent() public {
        uint256 amount = 1 ether;
        _deposit(alice, amount);

        vm.expectEmit(true, false, false, true, address(bank));
        emit Transfered(bob, amount);

        vm.prank(alice);
        bank.transfer(bob, amount);

        assertEq(bank.balances(alice), 0);
        assertEq(bank.balances(bob), amount);
        assertEq(address(bank).balance, amount);
    }

    function testTransferRevertsZeroAmount() public {
        _deposit(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert(ZeroAmount.selector);
        bank.transfer(bob, 0 ether);
    }

    function testTransferRevertsInsufficientBalance() public {
        _deposit(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert(InsufficientBalance.selector);
        bank.transfer(bob, 2 ether);
    }

    // owner withdraw
    receive() external payable {}

    function testOwnerWithdrawWorksAndEmitsEvent() public {
        _deposit(alice, 5 ether);
        uint256 amount = 3 ether;

        vm.expectEmit(false, false, false, true, address(bank));
        emit OwnerWithdrawn(amount);

        uint256 beforeBalance = owner.balance;
        bank.ownerWithdraw(amount);

        assertEq(address(bank).balance, 5 ether - amount);
        assertEq(owner.balance, beforeBalance + amount);
    }

    function testOwnerWithdrawRevertsOnlyOwner() public {
        _deposit(alice, 5 ether);

        vm.prank(alice);
        vm.expectRevert(OnlyOwner.selector);
        bank.ownerWithdraw(5 ether);
    }

    function testOwnerwithdrawRevertsZeroAmount() public {
        _deposit(alice, 1 ether);

        vm.expectRevert(ZeroAmount.selector);
        bank.ownerWithdraw(0 ether);
    }

    function testOwnerWithdrawRevertsInsufficientBalance() public {
        _deposit(alice, 1 ether);

        vm.expectRevert(InsufficientBalance.selector);
        bank.ownerWithdraw(2 ether);
    }

    // total bankBalance
    function testBankBalance() public {
        _deposit(alice, 1 ether);
        _deposit(bob, 2 ether);

        assertEq(bank.totalBankBalance(), address(bank).balance);
        assertEq(address(bank).balance, 3 ether);
    }

    // fuzz test
    function testFuzz_DepositAndWithdraw(uint256 amt) public {
        uint256 amount = bound(amt, 1, 10 ether);
        _deposit(alice, amount);

        vm.prank(alice);
        bank.withdraw(amount);

        assertEq(bank.balances(alice), 0);
        assertEq(address(bank).balance, 0);
        assertEq(alice.balance, amount);
    }

    function testFuzz_TransferKeepsTotalBalance(uint256 amt, uint256 transferAmt) public {
        uint256 amount = bound(amt, 1, 10 ether);
        _deposit(alice, amount);

        uint256 transferAmount = bound(transferAmt, 1, amount);
        uint256 lastTotal = bank.balances(alice) + bank.balances(bob);
        assertEq(lastTotal, amount);

        vm.prank(alice);
        bank.transfer(bob, transferAmount);

        uint256 newTotal = bank.balances(alice) + bank.balances(bob);
        assertEq(newTotal, lastTotal);
        assertEq(newTotal, amount);
        assertEq(address(bank).balance, amount);
    }
}
