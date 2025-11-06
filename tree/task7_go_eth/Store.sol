// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Store {

    event ItemSet(bytes32 key,bytes32 value);

    string public version;
    mapping (bytes32 =>bytes32) public items;

        (string memory _version){
        version = _version;
    }

    function setItem(bytes32 _key,bytes32 _value) external {
        items[_key] = _value;
        emit ItemSet(_key, _value);
    }
}