// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/BridgeETH.sol";
import "src/USDT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeETHTest is Test {
    event Deposit(address indexed depositor, uint256 amount);

    BridgeETH bridge;
    USDT usdt;
    USDT fakeToken;

    address user = address(0x1000);

    function setUp() public {
        usdt = new USDT();
        fakeToken = new USDT();
        bridge = new BridgeETH(address(usdt));
    }

    function _fundAndApprove(address who, uint256 amount) internal {
        usdt.mint(who, amount);
        vm.prank(who);
        usdt.approve(address(bridge), amount);
    }

    function test_Deposit_LocksTokensAndEmitsEvent() public {
        _fundAndApprove(user, 200);

        vm.expectEmit(true, false, false, true);
        emit Deposit(user, 200);

        vm.prank(user);
        bridge.deposit(IERC20(address(usdt)), 200);

        assertEq(usdt.balanceOf(user), 0);
        assertEq(usdt.balanceOf(address(bridge)), 200);
    }

    function test_Deposit_RevertsOnWrongToken() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.deposit(IERC20(address(fakeToken)), 200);
    }

    function test_Deposit_RevertsWithoutAllowance() public {
        usdt.mint(user, 200);

        vm.prank(user);
        vm.expectRevert();
        bridge.deposit(IERC20(address(usdt)), 200);
    }

    function test_Withdraw_ReleasesLockedTokens() public {
        _fundAndApprove(user, 200);
        vm.prank(user);
        bridge.deposit(IERC20(address(usdt)), 200);

        bridge.burnedOnOppositeChain(user, 150);

        vm.prank(user);
        bridge.withdraw(IERC20(address(usdt)), 150);

        assertEq(usdt.balanceOf(user), 150);
        assertEq(usdt.balanceOf(address(bridge)), 50);
    }

    function test_Withdraw_RevertsWithoutPendingBalance() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.withdraw(IERC20(address(usdt)), 100);
    }

    function test_Withdraw_RevertsWhenExceedingPendingBalance() public {
        _fundAndApprove(user, 200);
        vm.prank(user);
        bridge.deposit(IERC20(address(usdt)), 200);

        vm.prank(user);
        vm.expectRevert();
        bridge.withdraw(IERC20(address(usdt)), 201);
    }

    function test_BurnedOnOppositeChain_CreditsUser() public {
        bridge.burnedOnOppositeChain(user, 300);
        assertEq(bridge.pendingBalance(user), 300);
    }

    function test_BurnedOnOppositeChain_RevertsWithoutOwner() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.burnedOnOppositeChain(user, 300);
    }

    function test_FullOneWayRoundTrip() public {
        _fundAndApprove(user, 200);
        vm.prank(user);
        bridge.deposit(IERC20(address(usdt)), 200);

        bridge.burnedOnOppositeChain(user, 200);

        vm.prank(user);
        bridge.withdraw(IERC20(address(usdt)), 200);

        assertEq(usdt.balanceOf(user), 200);
        assertEq(usdt.balanceOf(address(bridge)), 0);
        assertEq(bridge.pendingBalance(user), 0);
    }

    function test_Withdraw_RevertsOnWrongToken() public {
        _fundAndApprove(user, 200);
        vm.prank(user);
        bridge.deposit(IERC20(address(usdt)), 200);

        bridge.burnedOnOppositeChain(user, 200);

        vm.prank(user);
        vm.expectRevert();
        bridge.withdraw(IERC20(address(fakeToken)), 200);
    }
}
