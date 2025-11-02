//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract UniswapV3Mock {

    mapping(address=> mapping(address=>address)) public getPair;

    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair){
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        ( address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB):(tokenB, tokenA);

        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS");

        //部署新的交易对合约
        pair = address(new UniswapV2PairMock(token0, token1));

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function allPairsLength() external view returns(uint){
        return allPairs.length;
    }


}

contract UniswapV2PairMock {
     address public token0;
     address public token1;

     constructor(address _token0, address _token1){
        token0 = _token0;
        token1 = _token1;
     }

     // 简化实现，仅用于测试
    function getReserves() external pure returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) {
        return (0, 0, 0);
    }
}



/**
 * @title UniswapV2Router02Mock
 * @dev Uniswap V2 Router的简化模拟实现，用于测试
 */

 contract UniswapV3Router02Mock {
       
       address public immutable factory;

       address public immutable WETH;

       constructor(address _factory){
        factory = _factory;
        WETH = address(new WETHMock());
       }


       function addLiquidityETH(
           address token,
           uint amountTokenDesired,
           uint amountTokenMin,
            uint amountETHMin,
            address to,
            uint deadline

       )external payable returns (uint amountToken, uint amountETH, uint liquidity){
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        
        // 简化实现：接收代币和ETH
        IERC20Mock(token).transferFrom(msg.sender, address(this), amountTokenDesired);
        
        return (amountTokenDesired, msg.value, 0);
       }


        /**
        * @dev Swap代币为ETH（模拟实现）
        */
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external {
            require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
            require(path.length >= 2, "UniswapV2Router: INVALID_PATH");
            
            // 从调用者接收代币
            IERC20Mock(path[0]).transferFrom(msg.sender, address(this), amountIn);
            
            // 模拟swap：发送等值的ETH（1 token = 0.00001 ETH用于测试）
            uint256 ethAmount = amountIn / 100000;
            if (address(this).balance >= ethAmount && ethAmount > 0) {
                payable(to).transfer(ethAmount);
            }
        }
        
        /**
        * @dev Swap ETH为代币（模拟实现）
        */
        function swapExactETHForTokensSupportingFeeOnTransferTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external payable {
            require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
            require(path.length >= 2, "UniswapV2Router: INVALID_PATH");
            
            // 模拟swap：发送代币
            uint256 tokenAmount = msg.value * 100000; // 简化汇率
            IERC20Mock(path[path.length - 1]).transfer(to, tokenAmount);
        }

       receive() external payable{} 



       
 }


//简化模拟实现
contract WETHMock {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";

     mapping(address=>uint256) public balanceOf;

     function deposit() public payable {
        balanceOf[msg.sender] +=msg.value;
     }

     function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender]>= amount);
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
     }

     receive() external payable {
        deposit();

     }
}

//接口ERC20

interface IERC20Mock {
     function transferFrom(address from, address to, uint256 amount)external returns(bool);
     
     function transfer(address to, uint256 amount) external returns(bool);

     function balanceOf(address account) external view returns(uint256);
}