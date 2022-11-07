// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Constant Product AMM is a market maker where pool tokens
 * follow the formula x * y = K
 * @dev this is a convex curve -> as x decreases, y increases and vice versa
 * @dev different from constant sum because dependence changes with pool balance
 * 
 */
contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint public reserve0;
    uint public reserve1;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _mint(address _to, uint _amount) private {
        // Code

        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint _amount) private {
        // Code
        balanceOf[_from] += _amount;
        totalSupply += _amount;

    }

    function swap(address _tokenIn, uint _amountIn)
        external
        returns (uint amountOut)
    {
        bool isToken0 = _tokenIn == address(token0);
        bool isToken1 = _tokenIn == address(token1);
        require(isToken0 || isToken1, "token address invalid");
        require(_amountIn > 0, "invalid amount to swap");
        require(reserve0 > 0 && reserve1 > 0, "pool empty");
        
        (IERC20 tokenIn, IERC20 tokenOut, uint reserveIn, uint reserveOut) = 
        
        isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);
        /*
        How many dy for dx?

        xy = k
        (x + dx)(y - dy) = k
        y - dy = k / (x + dx)
        y - k / (x + dx) = dy
        y - xy / (x + dx) = dy
        (yx + ydx - xy) / (x + dx) = dy
        ydx / (x + dx) = dy
        */
        uint amountIn = _amountIn * 997 /1000;    
        amountOut = reserveOut * amountIn / (reserveIn + amountIn);
        
        bool success = tokenIn.transferFrom( msg.sender, address(this), _amountIn);
        require(success, "transfer of token into pool failed");

        bool success1 = tokenOut.transfer(msg.sender, amountOut);
        require (success1, "transfer to sender from pool failed");
        
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
    }

    function addLiquidity(uint _amount0, uint _amount1)
        external
        returns (uint shares)
    {
        require(_amount1> 0 && _amount0 > 0, "invalid amounts");

        if(reserve0 > 0 || reserve1 > 0){
            
            // cannot use div -> div need not give a big number
            require(_amount0 * reserve1 == _amount1 * reserve0, "amounts out of proportion");
        }


        bool success = token0.transferFrom(msg.sender, address(this), _amount0);
        require(success, "failed to transfer token0 into pool");

        bool success1 = token1.transferFrom(msg.sender, address(this), _amount1);
        require(success1, "failed to transfer token1 into pool");

        if(totalSupply > 0){
            shares = _min(_amount0 * totalSupply / reserve0, _amount1 * totalSupply / reserve1);

        }
        else{
            shares = _sqrt(_amount0 * _amount1);
        }
        
        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        /*
        How many dx, dy to add?

        xy = k
        (x + dx)(y + dy) = k'

        No price change, before and after adding liquidity
        x / y = (x + dx) / (y + dy)

        x(y + dy) = y(x + dx)
        x * dy = y * dx

        x / y = dx / dy
        dy = y / x * dx
        */
        /*
        How many shares to mint?

        f(x, y) = value of liquidity
        We will define f(x, y) = sqrt(xy)

        L0 = f(x, y)
        L1 = f(x + dx, y + dy)
        T = total shares
        s = shares to mint

        Total shares should increase proportional to increase in liquidity
        L1 / L0 = (T + s) / T

        L1 * T = L0 * (T + s)

        (L1 - L0) * T / L0 = s 
        */
        /*
        Claim
        (L1 - L0) / L0 = dx / x = dy / y

        Proof
        --- Equation 1 ---
        (L1 - L0) / L0 = (sqrt((x + dx)(y + dy)) - sqrt(xy)) / sqrt(xy)
        
        dx / dy = x / y so replace dy = dx * y / x

        --- Equation 2 ---
        Equation 1 = (sqrt(xy + 2ydx + dx^2 * y / x) - sqrt(xy)) / sqrt(xy)

        Multiply by sqrt(x) / sqrt(x)
        Equation 2 = (sqrt(x^2y + 2xydx + dx^2 * y) - sqrt(x^2y)) / sqrt(x^2y)
                   = (sqrt(y)(sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2)) / (sqrt(y)sqrt(x^2))
        
        sqrt(y) on top and bottom cancels out

        --- Equation 3 ---
        Equation 2 = (sqrt(x^2 + 2xdx + dx^2) - sqrt(x^2)) / (sqrt(x^2)
        = (sqrt((x + dx)^2) - sqrt(x^2)) / sqrt(x^2)  
        = ((x + dx) - x) / x
        = dx / x

        Since dx / dy = x / y,
        dx / x = dy / y

        Finally
        (L1 - L0) / L0 = dx / x = dy / y
        */
    }

    function removeLiquidity(uint _shares)
        external
        returns (uint amount0, uint amount1)
    {
        require(_shares>0, "shares = 0");
        require(_shares<= totalSupply, " shares < totalSupply");
        require(totalSupply>0, "total supply = 0");

        uint token0Bal = token0.balanceOf(address(this));  
        uint token1Bal = token1.balanceOf(address(this));
        
        amount0 = (_shares * token0Bal) / totalSupply;
        amount1 = (_shares * token1Bal) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "amount0 & amount1 > 0");

        _burn(msg.sender, _shares);
        reserve0 = token0Bal- amount0;
        reserve1 = token1Bal- amount1;
        
        bool success = token0.transfer(msg.sender, amount0);
        require(success, "token0 withdrawal failed");

        bool success1 = token1.transfer(msg.sender, amount1);
        require(success1, "token1 withdrawal failed");
        



        /*
        How many tokens to withdraw?

        Claim
        dx, dy = amount of liquidity to remove
        dx = s / T * x
        dy = s / T * y

        Proof
        Let's find dx, dy such that
        v / L = s / T
        
        where
        v = f(dx, dy) = sqrt(dxdy)
        L = total liquidity = sqrt(xy)
        s = shares
        T = total supply

        --- Equation 1 ---
        v = s / T * L
        sqrt(dxdy) = s / T * sqrt(xy)

        Amount of liquidity to remove must not change price so 
        dx / dy = x / y

        replace dy = dx * y / x
        sqrt(dxdy) = sqrt(dx * dx * y / x) = dx * sqrt(y / x)

        Divide both sides of Equation 1 with sqrt(y / x)
        dx = s / T * sqrt(xy) / sqrt(y / x)
           = s / T * sqrt(x^2) = s / T * x

        Likewise
        dy = s / T * y
        */
    }

    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}
