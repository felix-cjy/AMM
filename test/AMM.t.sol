// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "../src/SimpleToken.sol";
import "../src/WETH.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMMTest is Test {
    AMM public amm;
    SimpleToken public token;
    WETH public weth;
    address public user1 = address(1);
    address public user2 = address(2);

    function setUp() public {
        // Deploy contracts
        token = new SimpleToken();
        weth = new WETH();
        amm = new AMM(IERC20(address(weth)), IERC20(address(token)));

        // Setup WETH for testing
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        weth.deposit{value: 10 ether}();

        vm.deal(user2, 10 ether);
        vm.prank(user2);
        weth.deposit{value: 10 ether}();

        // Transfer tokens to test users
        vm.startPrank(address(this));
        token.transfer(user1, 1000 ether);
        token.transfer(user2, 1000 ether);
        vm.stopPrank();
    }

    function testInitialState() public view {
        assertEq(address(amm.weth()), address(weth));
        assertEq(address(amm.token()), address(token));
        assertEq(amm.reserveWeth(), 0);
        assertEq(amm.reserveToken(), 0);
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);
        token.approve(address(amm), 100 ether);
        weth.approve(address(amm), 1 ether);
        uint256 liquidity = amm.addLiquidity(1 ether, 100 ether);
        vm.stopPrank();

        assertEq(liquidity, 10 ether);
        assertEq(amm.reserveWeth(), 1 ether);
        assertEq(amm.reserveToken(), 100 ether);
    }

    function testRemoveLiquidity() public {
        // First add liquidity
        vm.startPrank(user1);
        token.approve(address(amm), 100 ether);
        weth.approve(address(amm), 1 ether);
        uint256 liquidity = amm.addLiquidity(1 ether, 100 ether);

        // Now remove liquidity
        amm.approve(address(amm), liquidity);
        (uint256 amountWeth, uint256 amountToken) = amm.removeLiquidity(liquidity);
        vm.stopPrank();

        assertEq(amountWeth, 1 ether);
        assertEq(amountToken, 100 ether);
        assertEq(amm.reserveWeth(), 0);
        assertEq(amm.reserveToken(), 0);
    }

    function testSwapWETHForToken() public {
        // First add liquidity
        vm.startPrank(user1);
        token.approve(address(amm), 100 ether);
        weth.approve(address(amm), 1 ether);
        amm.addLiquidity(1 ether, 100 ether);
        vm.stopPrank();

        // Now swap
        vm.startPrank(user2);
        weth.approve(address(amm), 0.1 ether);
        (uint256 amountOut, IERC20 tokenOut) = amm.swap(0.1 ether, IERC20(address(weth)), 9 ether);
        vm.stopPrank();

        assertEq(address(tokenOut), address(token));
        assertApproxEqRel(amountOut, 9.070294784580498866 ether, 0.01e18); // 允许 1% 的误差
    }

    function testSwapTokenForWETH() public {
        // First add liquidity
        vm.startPrank(user1);
        token.approve(address(amm), 100 ether);
        weth.approve(address(amm), 1 ether);
        amm.addLiquidity(1 ether, 100 ether);
        vm.stopPrank();

        // Now swap
        vm.startPrank(user2);
        token.approve(address(amm), 10 ether);
        (uint256 amountOut, IERC20 tokenOut) = amm.swap(10 ether, IERC20(address(token)), 0.09 ether);
        vm.stopPrank();

        assertEq(address(tokenOut), address(weth));
        assertApproxEqRel(amountOut, 0.0909 ether, 0.01e18); // 允许 1% 的误差
    }

    function testGetAmount() public view {
        uint256 amountOut = amm.getAmount(1 ether, 10 ether, 100 ether);
        assertEq(amountOut, 9.090909090909090909 ether);
    }

    function testFailInsufficientLiquidity() public {
        vm.expectRevert("INSUFFICIENT_LIQUIDITY");
        vm.prank(user1);
        weth.approve(address(amm), 1 ether);
        amm.swap(1 ether, IERC20(address(weth)), 1 ether);
    }

    function testFailInvalidToken() public {
        SimpleToken invalidToken = new SimpleToken();
        vm.expectRevert("INVALID_TOKEN");
        vm.prank(user1);
        invalidToken.approve(address(amm), 1 ether);
        amm.swap(1 ether, IERC20(address(invalidToken)), 1 ether);
    }

    function testAddLiquidityTwice() public {
        vm.startPrank(user1);
        token.approve(address(amm), 200 ether);
        weth.approve(address(amm), 2 ether);

        uint256 liquidity1 = amm.addLiquidity(1 ether, 100 ether);
        uint256 liquidity2 = amm.addLiquidity(1 ether, 100 ether);

        vm.stopPrank();

        assertEq(liquidity1, 10 ether);
        assertApproxEqRel(liquidity2, 10 ether, 0.01e18); // 允许 1% 的误差
        assertEq(amm.reserveWeth(), 2 ether);
        assertEq(amm.reserveToken(), 200 ether);
    }

    function testRemoveLiquidityPartially() public {
        vm.startPrank(user1);
        token.approve(address(amm), 100 ether);
        weth.approve(address(amm), 1 ether);
        uint256 liquidity = amm.addLiquidity(1 ether, 100 ether);

        amm.approve(address(amm), liquidity / 2);
        (uint256 amountWeth, uint256 amountToken) = amm.removeLiquidity(liquidity / 2);
        vm.stopPrank();

        assertEq(amountWeth, 0.5 ether);
        assertEq(amountToken, 50 ether);
        assertEq(amm.reserveWeth(), 0.5 ether);
        assertEq(amm.reserveToken(), 50 ether);
    }
}
