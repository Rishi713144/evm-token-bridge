// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockUSDT {
    
    address private  usdtAddress;

    mapping(address => uint256)  pendingBalance;

    constructor(address _usdtAddress) {
        usdtAddress = _usdtAddress;
    }

    function deposit(uint256 _amount) public {
      require(IERC20(usdtAddress).allowance(msg.sender, address(this)) >= _amount);
      IERC20(usdtAddress).transferFrom(msg.sender, address(this), _amount);
      pendingBalance[msg.sender] += _amount;
    }

    function withdraw() public {
       uint256 remainingAmount = pendingBalance[msg.sender];
    
        IERC20(usdtAddress).transfer(msg.sender, remainingAmount);
        pendingBalance[msg.sender] = 0;
    }
}