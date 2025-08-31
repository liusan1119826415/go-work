
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//一个mapping来存储候选人的得票数
// 一个vote函数，允许用户投票给某个候选人
// 一个getVotes函数，返回某个候选人的得票数
// 一个resetVotes函数，重置所有候选人的得票数
contract Voting {
    
    mapping (address => uint) public VoteNum;

    mapping (address=>bool) public hasVoted;

    address [] public candidates;//记录所有候选人地址
    //只有合约所有者才能够重置
    address public owner;
    
    event ResetVotes(address indexed resetBy);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Only owner can call this");
        _;
    }


    
    function vote(address voteAddress)  external {
        //记录用户是否已经投过票
        require(!hasVoted[msg.sender],"You have already voted");

        require(voteAddress != address(0),"Cannot vote for zero address")

        //如果是新候选人
        if(VoteNum[voteAddress] == 0 && voteAddress != address(0)){
              candidates.push(voteAddress);
        }
        
        VoteNum[voteAddress] += 1;

        hasVoted[msg.sender] = true;
    }

    function getVotes(address voteAddress)  external view returns (uint) {
           
           return VoteNum[voteAddress];
    }

    function resetVotes() external onlyOwner{
        for(uint i = 0;i < len(candidates);i++){
            VoteNum[candidates[i]] = 0;
        }

        emit ResetVotes(msg.sender);

    }


}