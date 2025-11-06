import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

// 合约ABI (简化版，实际应从编译后的合约中获取)
const META_NODE_STAKE_ABI = [
  "function pools(uint256) view returns (address stTokenAddress, uint256 poolWeight, uint256 lastRewardBlock, uint256 accMetaNodePerShare, uint256 totalStaked, uint256 minDepositAmount, uint256 unstakeLockedBlocks)",
  "function users(uint256, address) view returns (uint256 stAmount, uint256 rewardDebt)",
  "function unstakeRequests(uint256, address, uint256) view returns (uint256 amount, uint256 unlockBlock)",
  "function poolCounter() view returns (uint256)",
  "function pendingReward(uint256 _pid, address _user) view returns (uint256)",
  "function deposit(uint256 _pid, uint256 _amount) payable",
  "function requestUnstake(uint256 _pid, uint256 _amount)",
  "function withdrawUnstaked(uint256 _pid)",
  "function claimReward(uint256 _pid)",
  "function getUnstakeRequests(uint256 _pid, address _user) view returns (tuple(uint256 amount, uint256 unlockBlock)[])",
  "function getWithdrawableAmount(uint256 _pid) view returns (uint256)"
];

const META_NODE_TOKEN_ABI = [
  "function approve(address spender, uint256 amount) returns (bool)",
  "function balanceOf(address account) view returns (uint256)",
  "function decimals() view returns (uint8)"
];

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [account, setAccount] = useState(null);
  const [contract, setContract] = useState(null);
  const [tokenContract, setTokenContract] = useState(null);
  const [pools, setPools] = useState([]);
  const [userStakes, setUserStakes] = useState([]);
  const [unstakeRequests, setUnstakeRequests] = useState([]);
  const [loading, setLoading] = useState(false);
  const [contractAddress, setContractAddress] = useState("");
  const [tokenAddress, setTokenAddress] = useState("");

  // 初始化钱包连接
  const connectWallet = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        const signer = provider.getSigner();
        const account = await signer.getAddress();
        
        setProvider(provider);
        setSigner(signer);
        setAccount(account);
        
        toast.success("钱包连接成功");
      } catch (error) {
        console.error("连接失败:", error);
        toast.error("钱包连接失败");
      }
    } else {
      toast.error("请安装MetaMask钱包");
    }
  };

  // 初始化合约
  const initContracts = async () => {
    if (!signer || !contractAddress || !tokenAddress) return;
    
    try {
      const stakeContract = new ethers.Contract(contractAddress, META_NODE_STAKE_ABI, signer);
      const tokenContractInstance = new ethers.Contract(tokenAddress, META_NODE_TOKEN_ABI, signer);
      
      setContract(stakeContract);
      setTokenContract(tokenContractInstance);
      
      await loadPools(stakeContract);
      toast.success("合约初始化成功");
    } catch (error) {
      console.error("合约初始化失败:", error);
      toast.error("合约初始化失败");
    }
  };

  // 加载质押池信息
  const loadPools = async (stakeContract) => {
    try {
      const poolCount = await stakeContract.poolCounter();
      const poolList = [];
      
      for (let i = 0; i < poolCount; i++) {
        const pool = await stakeContract.pools(i);
        poolList.push({
          id: i,
          stTokenAddress: pool.stTokenAddress,
          poolWeight: pool.poolWeight.toString(),
          totalStaked: ethers.utils.formatEther(pool.totalStaked),
          minDepositAmount: ethers.utils.formatEther(pool.minDepositAmount),
          unstakeLockedBlocks: pool.unstakeLockedBlocks.toString()
        });
      }
      
      setPools(poolList);
    } catch (error) {
      console.error("加载质押池失败:", error);
      toast.error("加载质押池失败");
    }
  };

  // 加载用户质押信息
  const loadUserStakes = async () => {
    if (!contract || !account) return;
    
    try {
      const userStakesList = [];
      
      for (let i = 0; i < pools.length; i++) {
        const userInfo = await contract.users(i, account);
        const pendingReward = await contract.pendingReward(i, account);
        const withdrawableAmount = await contract.getWithdrawableAmount(i);
        
        userStakesList.push({
          poolId: i,
          stakedAmount: ethers.utils.formatEther(userInfo.stAmount),
          pendingReward: ethers.utils.formatEther(pendingReward),
          withdrawableAmount: ethers.utils.formatEther(withdrawableAmount)
        });
      }
      
      setUserStakes(userStakesList);
    } catch (error) {
      console.error("加载用户质押信息失败:", error);
    }
  };

  // 加载解质押请求
  const loadUnstakeRequests = async () => {
    if (!contract || !account) return;
    
    try {
      const requestsList = [];
      
      for (let i = 0; i < pools.length; i++) {
        const requests = await contract.getUnstakeRequests(i, account);
        requests.forEach((req, index) => {
          requestsList.push({
            poolId: i,
            amount: ethers.utils.formatEther(req.amount),
            unlockBlock: req.unlockBlock.toString()
          });
        });
      }
      
      setUnstakeRequests(requestsList);
    } catch (error) {
      console.error("加载解质押请求失败:", error);
    }
  };

  // 质押代币
  const stakeTokens = async (poolId, amount, isNativeCurrency) => {
    if (!contract || !account) {
      toast.error("请先连接钱包并初始化合约");
      return;
    }
    
    setLoading(true);
    try {
      let tx;
      
      if (isNativeCurrency) {
        // Native currency质押
        tx = await contract.deposit(poolId, ethers.utils.parseEther(amount), {
          value: ethers.utils.parseEther(amount)
        });
      } else {
        // ERC20代币质押
        // 首先需要授权
        const approveTx = await tokenContract.approve(contract.address, ethers.utils.parseEther(amount));
        await approveTx.wait();
        
        tx = await contract.deposit(poolId, ethers.utils.parseEther(amount));
      }
      
      await tx.wait();
      toast.success("质押成功");
      loadUserStakes();
    } catch (error) {
      console.error("质押失败:", error);
      toast.error("质押失败: " + error.message);
    }
    setLoading(false);
  };

  // 请求解质押
  const requestUnstake = async (poolId, amount) => {
    if (!contract || !account) {
      toast.error("请先连接钱包并初始化合约");
      return;
    }
    
    setLoading(true);
    try {
      const tx = await contract.requestUnstake(poolId, ethers.utils.parseEther(amount));
      await tx.wait();
      toast.success("解质押请求已提交");
      loadUserStakes();
      loadUnstakeRequests();
    } catch (error) {
      console.error("解质押请求失败:", error);
      toast.error("解质押请求失败: " + error.message);
    }
    setLoading(false);
  };

  // 提取已解锁的代币
  const withdrawUnstaked = async (poolId) => {
    if (!contract || !account) {
      toast.error("请先连接钱包并初始化合约");
      return;
    }
    
    setLoading(true);
    try {
      const tx = await contract.withdrawUnstaked(poolId);
      await tx.wait();
      toast.success("已提取解锁的代币");
      loadUserStakes();
      loadUnstakeRequests();
    } catch (error) {
      console.error("提取失败:", error);
      toast.error("提取失败: " + error.message);
    }
    setLoading(false);
  };

  // 领取奖励
  const claimReward = async (poolId) => {
    if (!contract || !account) {
      toast.error("请先连接钱包并初始化合约");
      return;
    }
    
    setLoading(true);
    try {
      const tx = await contract.claimReward(poolId);
      await tx.wait();
      toast.success("奖励领取成功");
      loadUserStakes();
    } catch (error) {
      console.error("领取奖励失败:", error);
      toast.error("领取奖励失败: " + error.message);
    }
    setLoading(false);
  };

  // 组件挂载时尝试自动连接钱包
  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', () => {
        connectWallet();
      });
    }
  }, []);

  // 当合约或账户变化时重新加载数据
  useEffect(() => {
    if (contract && account) {
      loadUserStakes();
      loadUnstakeRequests();
    }
  }, [contract, account, pools]);

  return (
    <div className="App">
      <ToastContainer />
      <header className="app-header">
        <h1>MetaNode 质押系统</h1>
        <div className="wallet-section">
          {!account ? (
            <button onClick={connectWallet} className="connect-btn">连接钱包</button>
          ) : (
            <div className="account-info">
              <span>已连接: {account.substring(0, 6)}...{account.substring(account.length - 4)}</span>
            </div>
          )}
        </div>
      </header>

      <main className="app-main">
        <section className="contract-setup">
          <h2>合约设置</h2>
          <div className="input-group">
            <label>质押合约地址:</label>
            <input 
              type="text" 
              value={contractAddress} 
              onChange={(e) => setContractAddress(e.target.value)} 
              placeholder="0x..."
            />
          </div>
          <div className="input-group">
            <label>代币合约地址:</label>
            <input 
              type="text" 
              value={tokenAddress} 
              onChange={(e) => setTokenAddress(e.target.value)} 
              placeholder="0x..."
            />
          </div>
          <button onClick={initContracts} disabled={!contractAddress || !tokenAddress}>
            初始化合约
          </button>
        </section>

        {contract && (
          <>
            <section className="pools-section">
              <h2>质押池</h2>
              <div className="pools-grid">
                {pools.map((pool) => (
                  <PoolCard 
                    key={pool.id}
                    pool={pool}
                    userStake={userStakes.find(s => s.poolId === pool.id)}
                    onStake={stakeTokens}
                    onRequestUnstake={requestUnstake}
                    onWithdraw={withdrawUnstaked}
                    onClaim={claimReward}
                    loading={loading}
                  />
                ))}
              </div>
            </section>

            <section className="unstake-requests">
              <h2>解质押请求</h2>
              {unstakeRequests.length > 0 ? (
                <ul>
                  {unstakeRequests.map((req, index) => (
                    <li key={index}>
                      池 {req.poolId}: {req.amount} 代币, 解锁区块: {req.unlockBlock}
                    </li>
                  ))}
                </ul>
              ) : (
                <p>暂无解质押请求</p>
              )}
            </section>
          </>
        )}
      </main>
    </div>
  );
}

function PoolCard({ pool, userStake, onStake, onRequestUnstake, onWithdraw, onClaim, loading }) {
  const [stakeAmount, setStakeAmount] = useState("");
  const [unstakeAmount, setUnstakeAmount] = useState("");
  const isNativeCurrency = pool.stTokenAddress === ethers.constants.AddressZero;

  return (
    <div className="pool-card">
      <h3>质押池 #{pool.id}</h3>
      <div className="pool-info">
        <p>代币类型: {isNativeCurrency ? "Native Currency (ETH)" : "ERC20 Token"}</p>
        <p>权重: {pool.poolWeight}</p>
        <p>最小质押: {pool.minDepositAmount} {isNativeCurrency ? "ETH" : "Tokens"}</p>
        <p>解锁区块数: {pool.unstakeLockedBlocks}</p>
      </div>

      {userStake && (
        <div className="user-info">
          <p>已质押: {userStake.stakedAmount} {isNativeCurrency ? "ETH" : "Tokens"}</p>
          <p>待领取奖励: {userStake.pendingReward} MTN</p>
          <p>可提取: {userStake.withdrawableAmount} {isNativeCurrency ? "ETH" : "Tokens"}</p>
        </div>
      )}

      <div className="actions">
        <div className="action-group">
          <input 
            type="number" 
            value={stakeAmount} 
            onChange={(e) => setStakeAmount(e.target.value)} 
            placeholder="质押数量"
          />
          <button 
            onClick={() => onStake(pool.id, stakeAmount, isNativeCurrency)} 
            disabled={loading}
          >
            质押
          </button>
        </div>

        <div className="action-group">
          <input 
            type="number" 
            value={unstakeAmount} 
            onChange={(e) => setUnstakeAmount(e.target.value)} 
            placeholder="解质押数量"
          />
          <button 
            onClick={() => onRequestUnstake(pool.id, unstakeAmount)} 
            disabled={loading}
          >
            请求解质押
          </button>
        </div>

        <div className="action-buttons">
          <button 
            onClick={() => onWithdraw(pool.id)} 
            disabled={loading || !userStake || parseFloat(userStake.withdrawableAmount) <= 0}
          >
            提取已解锁代币
          </button>
          <button 
            onClick={() => onClaim(pool.id)} 
            disabled={loading || !userStake || parseFloat(userStake.pendingReward) <= 0}
          >
            领取奖励
          </button>
        </div>
      </div>
    </div>
  );
}

export default App;