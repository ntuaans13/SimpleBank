// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank internal bank;
    address[] internal actors;
    address internal owner;
    uint256 internal ownerWithdrawn;


    function setUp() public {
        owner = address(this);
        bank = new SimpleBank();
        
        ownerWithdrawn = 0;
        actors = new address[](3);
        for(uint256 i = 0; i < 3; ) {
            actors[i] = address(uint160(0x1 + i));
            unchecked {
                ++i;
            }
        }
    }

    //helper
    function _deposit(address sender, uint256 amount) internal {
        vm.deal(sender, amount);
        vm.prank(sender);
        bank.deposit{value: amount}();
    }

    receive() external payable {}

    function _randomScenario(uint256 seed) internal {
        uint256 numActors = actors.length;

        for (uint256 i = 0; i < numActors; ) {
            address user = actors[i];
            uint256 action = uint256(keccak256(abi.encode(seed, i, "action"))) % 4;

            if (action == 0) {
                uint256 amount = (uint256(keccak256(abi.encode(seed, i, "deposit"))) % 1 ether) + 1;
                _deposit(user, amount);
            } else if (action == 1) {
                uint256 bal = bank.balances(user);
                if (bal > 0) {
                    uint256 amount = (uint256(keccak256(abi.encode(seed, i, "withdraw"))) % bal) + 1;

                    vm.prank(user);
                    bank.withdraw(amount);
                }
            } else if (action == 2) {
                uint256 bal = bank.balances(user);
                if (bal > 0) {
                    address to = actors[(i + 1) % numActors]; 
                    uint256 amount = (uint256(keccak256(abi.encode(seed, i, "transfer"))) % bal) + 1;

                    vm.prank(user);
                    bank.transfer(to, amount);
                }
            } else {
                uint256 bankBal = address(bank).balance;
                if (bankBal > 0) {
                    uint256 amount = (uint256(keccak256(abi.encode(seed, i, "owner"))) % bankBal) + 1;
                    uint256 before = address(bank).balance;

                    vm.prank(owner);
                    bank.ownerWithdraw(amount);

                    ownerWithdrawn += amount;
                    assertEq(before - amount, address(bank).balance);
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _sumActorBalances() internal view returns (uint256 sum) {
        uint256 len = actors.length;
        for (uint256 i = 0; i < len; ) {
            sum += bank.balances(actors[i]);
            unchecked {
                ++i;
            }
        }
    }

    function testInvariant_BankSolvent(uint256 seed) public {
        _randomScenario(seed);

        uint256 sumBalances = _sumActorBalances();
        uint256 availableValue = address(bank).balance + ownerWithdrawn;

        assertGe(availableValue, sumBalances);
    }
}