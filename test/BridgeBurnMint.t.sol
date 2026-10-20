// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "src/BridgeBase.sol";
import "src/BUSDT.sol";

contract BridgeBurnMintTest is Test {
    event Burn(address indexed burner, uint256 amount);

    BridgeBurnMint bridge;
    BUSDT token;

    address user = address(0x1000);

    function setUp() public {
        token = new BUSDT();
        token.mint(user, 1_000);
        bridge = new BridgeBurnMint(address(token));
        token.transferOwnership(address(bridge));
    }

    function test_Burn_BurnsUserTokens() public {
        vm.startPrank(user);
        token.approve(address(bridge), 200);

        vm.expectEmit(true, false, false, true);
        emit Burn(user, 150);
        bridge.burn(IBUSDT(address(token)), 150);
        vm.stopPrank();

        assertEq(token.balanceOf(user), 850);
    }

    function test_Burn_RevertsOnWrongToken() public {
        BUSDT wrongToken = new BUSDT();
        wrongToken.mint(user, 200);
        vm.startPrank(user);
        wrongToken.approve(address(bridge), 200);
        vm.expectRevert();
        bridge.burn(IBUSDT(address(wrongToken)), 200);
        vm.stopPrank();
    }

    function test_Withdraw_MintsAfterCredit() public {
        bridge.depositedOnOppositeChain(user, 100);
        assertEq(bridge.pendingBalance(user), 100);

        vm.prank(user);
        bridge.withdraw(IBUSDT(address(token)), 60);

        assertEq(token.balanceOf(user), 1_060);
        assertEq(bridge.pendingBalance(user), 40);
    }

    function test_Withdraw_RevertsWithoutCredit() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.withdraw(IBUSDT(address(token)), 1);
    }

    function test_Withdraw_RevertsOnWrongToken() public {
        BUSDT wrongToken = new BUSDT();
        bridge.depositedOnOppositeChain(user, 100);

        vm.prank(user);
        vm.expectRevert();
        bridge.withdraw(IBUSDT(address(wrongToken)), 100);
    }

    function test_DepositedOnOppositeChain_OnlyOwner() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.depositedOnOppositeChain(user, 100);
    }

    function test_FullBurnMintRoundTrip() public {
        vm.startPrank(user);
        token.approve(address(bridge), 200);
        bridge.burn(IBUSDT(address(token)), 200);
        vm.stopPrank();

        assertEq(token.totalSupply(), 800);

        bridge.depositedOnOppositeChain(user, 200);
        vm.prank(user);
        bridge.withdraw(IBUSDT(address(token)), 200);

        assertEq(token.balanceOf(user), 1_000);
        assertEq(bridge.pendingBalance(user), 0);
    }
}
