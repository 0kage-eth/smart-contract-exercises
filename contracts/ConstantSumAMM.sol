// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @notice contract is written for a constant sum AMM
 * @dev X + Y = K -> constant sum
 * @dev tokens can be swapped into a pool -> swap X token and get back Y token
 * @dev X + dx + Y - dy = K => dx = dy
 * @dev In this contract we learn how to add/remove liquidity and swap tokens in a pool
 */

contract ConstantSumAMM{

    IERC20 public immutable token0; // token 0 -> first token in pool
    IERC20 public immutable token1; // token 1 -> second token in pool

    uint public reserve0;   // existing reserve of token 0 in the pool
    uint public reserve1;   // existing reserve of token 1 in the pool

    uint public totalSupply; // total supply of shares that represent pool ownership
    mapping(address => uint) public balanceOf; // mapping that maps address with pool tokens

    constructor(address _token0, address _token1) {
        // NOTE: This contract assumes that token0 and token1
        // both have same decimals
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /**
     * @dev mint new shares for LPs who supply tokens to pool
     */
    function _mint(address _to, uint _amount) private {
        // Write code here
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    /**
     * @dev burn shares when LPs want to redeem shares for their tokens
     */
    function _burn(address _from, uint _amount) private {
        // Write code here

        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    /**
     * @dev swap tokenIn/amountIn for tokenOut/amountOut
     * @dev make transfers, adjust the reserves
     * @dev note that swap does not change the ownership of LPs
     */
    function swap(address _tokenIn, uint _amountIn)
        external
        returns (uint amountOut)
    {
        // Write code here
        bool isToken0 = _tokenIn == address(token0);
        bool isToken1 = _tokenIn == address(token1);
        require( isToken0 || isToken1 , "invalid token to swap");
        IERC20 tokenInERC20 = isToken0 ? token0 : token1; 
        IERC20 tokenOutERC20 = isToken0 ? token1 : token0;

        bool success1 = tokenInERC20.transferFrom(msg.sender, address(this), _amountIn);
        require(success1, "token in transfer failed");

        amountOut = 997 * _amountIn / 1000;
        bool success2 = tokenOutERC20.transfer(msg.sender, amountOut);
        require(success2, "token out transfer failed");

        reserve0 = isToken0 ? reserve0 + _amountIn : reserve0 - amountOut;
        reserve1 = isToken1 ? reserve1 + _amountIn : reserve0 - amountOut;
    }

    /**
     * @notice function adds liquidity to the pool
     * @dev need to submit amount0 and amount1 proportionately
     * @dev shares are minted to the LP who is providing liquidity
     */
    function addLiquidity(uint _amount0, uint _amount1)
        external
        returns (uint shares)
    {
        // Write code here
        require(shares > 0, "Shares should be greater than 0");
 
        // transfer token0 and token 
        bool success0 = token0.transferFrom(msg.sender, address(this), _amount0);
        bool success1 = token1.transferFrom(msg.sender, address(this), _amount1);

        require(success0 && success1, "token transfers failed");

        if(reserve0 + reserve1 == 0){
            shares = _amount0 + _amount1; // total liquidity
        }
        else{
            shares = (_amount0 + _amount1) * totalSupply / (reserve1 + reserve0);
        }

        require(shares > 0, "invalid shares to mint");

        reserve0 += _amount0;
        reserve1 += _amount1;

        balanceOf[msg.sender] += shares;
        totalSupply += shares;
    }

    /**
     * @notice removes liquidity from pool
     * @dev burns the shares -> calcilaotes LP tokens that need to be sent back to user
     * @dev makes transfers 
     */
    function removeLiquidity(uint _shares) external returns (uint d0, uint d1) {
        // Write code here
        
        require(_shares >0 , "shares == 0");
        require(_shares <=totalSupply , "shares <= total supply");
        require(totalSupply > 0, "total supply in pool == 0");
        
        d0 = _shares * reserve0 / totalSupply;
        d1 = _shares * reserve1 / totalSupply;

        bool success0 = token0.transfer(msg.sender, d0);
        require(success0, "token0 transfer failed");

        bool success1 = token1.transfer(msg.sender, d1);
        require(success1, "token1 transfer failed");

        balanceOf[msg.sender] -= _shares;
        totalSupply -= _shares;        
        reserve0 -= d0;
        reserve1 -= d1;

    }
}