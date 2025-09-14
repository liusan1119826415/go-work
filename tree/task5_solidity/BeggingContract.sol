//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BeggingContract {

    mapping(address => uint256) public donations;

    address public owner;

    //捐赠地址
    address[] public donorList;

    //捐赠开始时间
    uint256 public startTime;

    //捐赠结束时间

    uint256 public endTime;

    //捐赠事件
    event DonateReceived(address indexed donor,uint256 amount);

    
    constructor(uint256 _startTime, uint256 _endTime){
        require(_endTime > _startTime,"endTime must be greater than startTime");
        startTime = _startTime;
        endTime = _endTime;
        owner = msg.sender;
      
    }

    function donate() external payable {
        require(msg.value >0,"donation must be greater than 0");
        require(block.timestamp>= startTime && block.timestamp <= endTime,"donation period is not active");
        if(donations[msg.sender] == 0){
            donorList.push(msg.sender);
        }
        donations[msg.sender] += msg.value;
        emit DonateReceived(msg.sender, msg.value);



    }

    //捐赠排行榜
    function topDonors() external view returns(address[3] memory topDonors, uint256[3] memory topAmounts){
        uint256 length = donorList.length;

        for(uint256 i = 0; i< length;i++){
            address donor  = donorList[i];
            uint256 amount = donations[donor];
            //插入排序
            for(uint256 j = 0; j<3;j++){
                if(amount >topAmounts[j]){
                    //后移
                    for(uint256 k=2; k>j;k--){
                        topAmounts[k] = topAmounts[k-1];
                        topDonors[k] = topDonors[k-1];
                    }

                    topAmounts[j] = amount;
                    topDonors[j] = donor;

                }
            }
        }
    }


    function withdraw() external {
        require(msg.sender == owner,"owner only can withdraw");
        uint256 amount = address(this).balance;
        require(amount >0 ,"contract balance is zero");
        payable(owner).transfer(amount);
    }

    function getDonation (address donor)external view returns(uint256){
        return donations[donor];
    }

    

}