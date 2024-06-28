// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Withdrawable is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Withdrawal(uint amount, uint when);
    event WithdrawalERC20(uint amount, uint when, IERC20 token);

    function withdraw() public onlyOwner nonReentrant {
        emit Withdrawal(address(this).balance, block.timestamp);
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 token) public onlyOwner nonReentrant {
        emit WithdrawalERC20(token.balanceOf(address(this)), block.timestamp, token);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    receive() external payable {
        // do nothing
    }
}