// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// 题目: 实现一个基于常数乘积的 AMM 流动性池, WETH和任意token

// 核心公式: k=x*y
// k为两种代币的乘积,计算原理:用户用x兑换y代币时,k值是确定的,x的总数增加,则y下降,y的减量就是用户兑换出来的数量.
// 例如初始数量都为10,k为100,用10个x兑换,能换出5个y,池子变为20个x,5个y.
// 从1:1为4:1,自动地反映了市场对两种token的供需关系.

// 当添加流动性或移除移动性时,k值会变化.
// K 值的变化并不影响两种代币的相对价值, 相当于只是帮助计算的工具值

// K 值越大，价格曲线越平缓, 兑换预期越稳定，K 值越小，价格曲线越陡峭

// k值由市场自动调节, 如果k值与市场认可价格有偏差,则存在套利空间,套利行为会让k值变回市场认可价格
// 流动性提供者可以赚取交易手续费。如果 K 值设置不合理，导致交易量减少或无常损失增加，
// 流动性提供者可以移除流动性, 或将流动性转移到其他的池子，从而促使 K 值回归合理

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WETH} from "./WETH.sol";

// 交易所token用于提供LP份额
contract AMM is ERC20 {
    IERC20 public weth;
    IERC20 public token;

    uint256 public reserveWeth;
    uint256 public reserveToken;

    event Mint(address indexed sender, uint256 amountWeth, uint256 amountToken);
    event Burn(address indexed sender, uint256 amountWeth, uint256 amountToken);
    event Swap(address indexed sender, uint256 amountIn, address tokenIn, uint256 amountOut, address tokenOut);

    constructor(IERC20 _weth, IERC20 _token) ERC20("ETHSwap", "ES") {
        // weth = WETH(address(0x00...))
        weth = _weth;
        token = _token;
    }

    // 取小值
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // 平方根, 来源https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/Babylonian.sol
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    function addLiquidity(uint256 amountWeth, uint256 amountToken) external returns (uint256 liquidity) {
        weth.transferFrom(msg.sender, address(this), amountWeth);
        token.transferFrom(msg.sender, address(this), amountToken);

        uint256 _totalLiquidity = totalSupply();

        if (_totalLiquidity == 0) {
            // 首次添加流动性
            liquidity = sqrt(amountWeth * amountToken);
        } else {
            //后续添加, 计算增加量与池内储量的占比,选用更小的比例进行计算
            liquidity = _totalLiquidity * min(amountWeth / reserveWeth, amountToken / reserveToken);
        }

        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");

        reserveWeth = weth.balanceOf(address(this));
        reserveToken = token.balanceOf(address(this));

        _mint(msg.sender, liquidity);

        emit Mint(msg.sender, amountWeth, amountToken);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountWeth, uint256 amountToken) {
        // 计算转出数量
        uint256 balanceWeth = weth.balanceOf(address(this));
        uint256 balanceToken = token.balanceOf(address(this));
        // 不直接读取reserve, 合约面向许多用户交易, 数量可能已经变动,但reserve还没更新
        // balanceOf查询的是源数据, 可靠性更高, 即使gas消耗多一点

        uint256 _totalLiquidity = totalSupply();

        amountWeth = balanceWeth * liquidity / _totalLiquidity;
        amountToken = balanceToken * liquidity / _totalLiquidity;

        // 销毁LP
        _burn(msg.sender, liquidity);

        weth.transfer(msg.sender, amountWeth);
        token.transfer(msg.sender, amountToken);

        reserveWeth = weth.balanceOf(address(this));
        reserveToken = token.balanceOf(address(this));

        emit Burn(msg.sender, amountWeth, amountToken);
    }

    // k=x∗y=(x+Δx)∗(y+Δy)
    // (reserveIn + amountIn)*(reserveOut - amountOut)
    function getAmount(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "INSUFFICIENT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }

    // amountOutMin 设置预期最低值
    function swap(uint256 amountIn, IERC20 tokenIn, uint256 amountOutMin)
        external
        returns (uint256 amountOut, IERC20 tokenOut)
    {
        require(amountIn > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(tokenIn == weth || tokenIn == token, "INVALID_TOKEN");

        uint256 balanceWeth = weth.balanceOf(address(this));
        uint256 balanceToken = token.balanceOf(address(this));

        if (tokenIn == weth) {
            tokenOut = token;
            amountOut = getAmount(amountIn, balanceWeth, balanceToken);
            require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        } else {
            // tokenIn == token
            tokenOut = weth;

            amountOut = getAmount(amountIn, balanceToken, balanceWeth);
            require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }

        reserveWeth = weth.balanceOf(address(this));
        reserveToken = token.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}
