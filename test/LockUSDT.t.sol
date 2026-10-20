// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/LockUSDT.sol";
import "src/USDT.sol";

contract LockUSDTTest is Test {
    LockUSDT bridge;
    USDT usdt;

    address user = address(0x1000);

    function setUp() public {
        usdt = new USDT();
        bridge = new LockUSDT(address(usdt));
    }

    function test_DepositAndPartialWithdraw() public {
        usdt.mint(user, 200);
        vm.startPrank(user);
        usdt.approve(address(bridge), 200);
        bridge.deposit(200);

        assertEq(usdt.balanceOf(user), 0);
        assertEq(usdt.balanceOf(address(bridge)), 200);

        bridge.withdraw();
        vm.stopPrank();

        assertEq(usdt.balanceOf(user), 200);
        assertEq(usdt.balanceOf(address(bridge)), 0);
    }

    function test_Deposit_RevertsWithoutAllowance() public {
        usdt.mint(user, 200);
        vm.prank(user);
        vm.expectRevert();
        bridge.deposit(200);
    }
}
