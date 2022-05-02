pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
  uint256 public constant tokensPerEth = 100;
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller,  uint256 amountOfETH, uint256 amountOfTokens);
  YourToken public yourToken;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  function buyTokens() external payable {
    uint ethConvertedToTokens = msg.value * tokensPerEth;
    yourToken.transfer(msg.sender, ethConvertedToTokens);
    emit BuyTokens(msg.sender, msg.value, ethConvertedToTokens);
  }

  function withdraw() external onlyOwner {
    (bool sent, ) = payable(msg.sender).call{value: address(this).balance}('');
    require(sent, 'Failed to withdraw ether');
  } 

  function sellTokens(uint _amount) external {
    uint tokensConvertedToEth = _amount / tokensPerEth;
    yourToken.transferFrom(msg.sender, address(this), _amount);
    (bool sent, ) = payable(msg.sender).call{value: tokensConvertedToEth}('');
    require(sent, 'Failed to sell token');
    emit SellTokens(msg.sender, tokensConvertedToEth, _amount);
  }

}
