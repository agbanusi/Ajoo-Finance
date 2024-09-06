// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract UniswapYieldStrategy is ReentrancyGuard, AccessControl {
    IUniswapV3Pool public immutable pool;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    ISwapRouter public immutable swapRouter;
    IERC20 public immutable usdtToken;
    IERC20 public immutable wethToken;
    uint24 public immutable fee;

    int24 public tickLower;
    int24 public tickUpper;
    uint256 public tokenId;
    uint24 public constant TICK_RANGE = 100;
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant USER_ROLE_ADMIN = keccak256("USER_ROLE_ADMIN");

    event Deposited(address indexed user, uint256 amountUsdt, uint256 amountWeth);
    event Withdrawn(address indexed user, uint256 amountUsdt, uint256 amountWeth);
    event YieldHarvested(address indexed user, uint256 amountUsdt, uint256 amountWeth);

    constructor(
        address _usdtToken,
        address _wethToken,
        address _pool,
        address _nonfungiblePositionManager,
        address _swapRouter,
        uint24 _fee,
        address _owner
        // address _proxy
    ) {
        usdtToken = IERC20(_usdtToken);
        wethToken = IERC20(_wethToken);
        pool = IUniswapV3Pool(_pool);
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
        swapRouter = ISwapRouter(_swapRouter);
        fee = _fee;

        _setRoleAdmin(USER_ROLE, USER_ROLE_ADMIN);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(USER_ROLE, _owner);
        _grantRole(USER_ROLE_ADMIN, _owner);
        _grantRole(USER_ROLE, msg.sender);
    }

    function deposit(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        require(amount > 0, "INVALID_AMOUNT");
        (uint160 sqrtPriceX96, int24 currentTick,,,,,) = pool.slot0();
        
        if (tickLower == 0 && tickUpper == 0) {
            (tickLower, tickUpper) = _calculateNewTickRange(currentTick);
        }

        TransferHelper.safeTransferFrom(address(usdtToken), msg.sender, address(this), amount);

        uint256 amountToSwap = amount / 2;
        uint256 amountOutMinimum = amountToSwap * 250 / 10000; // 2.50%
        TransferHelper.safeApprove(address(usdtToken), address(swapRouter), amountToSwap);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(usdtToken),
                tokenOut: address(wethToken),
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountToSwap,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(params);

        TransferHelper.safeApprove(address(usdtToken), address(nonfungiblePositionManager), amount - amountToSwap);
        TransferHelper.safeApprove(address(wethToken), address(nonfungiblePositionManager), amountOut);

        INonfungiblePositionManager.MintParams memory mintParams =
            INonfungiblePositionManager.MintParams({
                token0: address(usdtToken),
                token1: address(wethToken),
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount - amountToSwap,
                amount1Desired: amountOut,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        if (tokenId == 0) {
            (uint256 _tokenId,, uint256 amount0, uint256 amount1) = nonfungiblePositionManager.mint(mintParams);
            tokenId = _tokenId;
            emit Deposited(msg.sender, amount0, amount1);
        } else {
            _rebalance();
            (uint128 liquidityAdded, uint256 amount0, uint256 amount1) = nonfungiblePositionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: mintParams.amount0Desired,
                    amount1Desired: mintParams.amount1Desired,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
            emit Deposited(msg.sender, amount0, amount1);
        }
    }

    function withdraw(uint256 amount) external onlyRole(USER_ROLE) nonReentrant {
        require(tokenId != 0, "NO_POSITION");
        require(amount > 0, "INVALID_AMOUNT");
        
        _rebalance();

        (, , , , , , , uint128 currentLiquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);
        uint256 totalValue = getTotalValue();
        require(amount <= totalValue, "INSUFFICIENT_BALANCE");

        uint128 liquidityToWithdraw = uint128((uint256(currentLiquidity) * amount) / totalValue);

        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidityToWithdraw,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        TransferHelper.safeTransfer(address(usdtToken), msg.sender, amount0);
        TransferHelper.safeTransfer(address(wethToken), msg.sender, amount1);

        emit Withdrawn(msg.sender, amount0, amount1);
    }

    function harvestYield() external onlyRole(USER_ROLE) nonReentrant {
        require(tokenId != 0, "NO_POSITION");

        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        require(amount0 > 0 || amount1 > 0, "NO_YIELD");

        TransferHelper.safeTransfer(address(usdtToken), msg.sender, amount0);
        TransferHelper.safeTransfer(address(wethToken), msg.sender, amount1);

        emit YieldHarvested(msg.sender, amount0, amount1);
    }

    function _rebalance() internal {
        (, int24 currentTick,,,,,) = pool.slot0();
        
        if (currentTick < tickLower || currentTick > tickUpper) {
            (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );

            (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);
            (uint256 amount0Removed, uint256 amount1Removed) = nonfungiblePositionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );

            amount0 += amount0Removed;
            amount1 += amount1Removed;

            nonfungiblePositionManager.burn(tokenId);

            (int24 newTickLower, int24 newTickUpper) = _calculateNewTickRange(currentTick);

            INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
                token0: address(usdtToken),
                token1: address(wethToken),
                fee: fee,
                tickLower: newTickLower,
                tickUpper: newTickUpper,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

            (tokenId,,,) = nonfungiblePositionManager.mint(params);

            tickLower = newTickLower;
            tickUpper = newTickUpper;
        }
    }

    function getTotalValue() public view returns (uint256 totalValue) {
        if (tokenId == 0) return 0;

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = nonfungiblePositionManager.positions(tokenId);

        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );

        amount0 += tokensOwed0;
        amount1 += tokensOwed1;

        totalValue = amount0 * 2; //placeholder rough estimate  //  + _convertWethToUsdt(amount1);
    }

    function _calculateNewTickRange(int24 currentTick) internal view returns (int24, int24) {
        int24 tickSpacing = pool.tickSpacing();
        int24 tickLower = ((currentTick - int24(TICK_RANGE)) / tickSpacing) * tickSpacing;
        int24 tickUpper = ((currentTick + int24(TICK_RANGE)) / tickSpacing) * tickSpacing;
        return (tickLower, tickUpper);
    }

    function _convertWethToUsdt(uint256 wethAmount) internal view returns (uint256) {
        // Implement WETH to USDT conversion logic here
        // This could use an oracle, a TWAP from Uniswap, or another price feed
        // For simplicity, we're returning the input amount, but you should replace this with actual conversion logic
        return wethAmount;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external view returns (bytes4) {
        require(msg.sender == address(nonfungiblePositionManager), "INVALID_NFT");
        return this.onERC721Received.selector;
    }
}