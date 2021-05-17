// SPDX-License-Identifier: SimPL-2.0

pragma solidity ^0.7.0;

import "./common/Utils.sol";
import "./common/Common.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title The Three Kingdoms OKT Mortgage
 *
 * @author Bit Lighthouse. Ace
 * AT: 2021-3-28 | VERSION: v1.0.2
 */
contract OktMortgage is Common, Utils {
    using SafeMath for uint256;

    uint256 private _total;

    mapping(address => uint256) private _balances;
    mapping(address => uint256[]) private _detail;

    function _calc(address _owner) private view returns (uint256) {
        if (_detail[_owner].length <= 0) {
            return 0;
        }

        (uint256 _daily, ) = getRewardsConfig("OkChain");
        uint256 second = _daily.div(24 hours);

        uint256 mydeposits = _detail[_owner][1];
        uint256 deposits = mydeposits.mul(100).div(_total);

        uint256 duration = block.timestamp - _detail[_owner][0];

        return second.mul(deposits).mul(duration).div(100);
    }

    function deposit() public payable {
        claim(msg.sender);
        _total = _total.add(msg.value);

        if (_detail[msg.sender].length <= 0) {
            _detail[msg.sender] = new uint256[](2);
            _detail[msg.sender][1] = msg.value;
        } else {
            _detail[msg.sender][1] = _detail[msg.sender][1].add(msg.value);
        }
        
        _detail[msg.sender][0] = block.timestamp;
    }

    function withdraw() public {
        require(
            _detail[msg.sender][1] > 0,
            "NFT-RICH: Wrong transaction amount"
        );

        uint256 lock = TIMELOCK_FOR_MORTGAGE;
        uint256 depo = _detail[msg.sender][0];

        require(
            (depo + lock) - block.timestamp < 0,
            "RICH-NFT: Cannot withdraw back now"
        );

        address payable to = payable(msg.sender);
        to.transfer(_detail[msg.sender][1]);
        _total = _total.sub(_detail[msg.sender][1]);

        delete _detail[msg.sender];
    }

    function claim(address _owner) public returns (uint256){
        uint256 rewards = _calc(_owner);
        if (rewards <= 0) { return 0; }
        
        address token = manager.members("RttToken");
        transfer20(token, address(0), msg.sender, rewards);
        _detail[msg.sender][0] = block.timestamp;

        return rewards;
    }
    
    function getRewards(address _owner) external view
        returns (uint256) {

        uint256 rewards = _calc(_owner);
        return rewards > 0 ? rewards.mul(10 ** 8) : 0;
    }

    function getMyValueLock(address _owner) external view returns (uint256) {
        bool is_deposit = _detail[_owner].length > 0;
        return is_deposit ? _detail[_owner][1] : 0;
    }

    function getTotalValueLock() external view returns (uint256) {
        return _total;
    }

    function getTokenAPY() external view returns (uint256) {
        (, uint256 _rTotal) = getRewardsConfig("OkChain");
        bool is_zero = (_rTotal != 0 && _total != 0);

        return is_zero ? _rTotal.div(_total).mul(365) : 0;
    }

    function getDepositTime(address _owner) external view
        returns (uint256) {

        if (_detail[_owner].length <= 0) { return 0; }
        return _detail[_owner][0].add(TIMELOCK_FOR_MORTGAGE);
    }
}