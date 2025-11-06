// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
contract Mtoken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    constructor(uint256 initialSupply) ERC20("MToken", "MTKN") {
          _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
          _setupRole(MINTER_ROLE, msg.sender);
          _mint(msg.sender, initialSupply);
    } 

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE){
        _mint(account, amount);
    }
    


}
