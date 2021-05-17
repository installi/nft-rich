// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract TestPayable {
    using SafeMath for uint256;

    uint256 private _total;

    mapping(address => uint256) private _balances;
    mapping(address => uint256[]) private _detail;

    function deposit() public payable {
        _total = _total.add(msg.value);

        _detail[msg.sender] = new uint256[](2);
        _detail[msg.sender][0] = block.timestamp;
        _detail[msg.sender][1] = msg.value;
    }

    function getBalance() public view returns(uint, uint) {
        return (address(this).balance, _detail[msg.sender][1]);
    }

    function withdrawMoney() public {
        require(_balances[msg.sender] > 0, "not enugh");
        address payable to = payable(msg.sender);
        to.transfer(_balances[msg.sender]);
        _balances[msg.sender] -= _balances[msg.sender];
    }
}