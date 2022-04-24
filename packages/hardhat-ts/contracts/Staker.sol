pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;
  mapping(address => uint256) public balances;
  event Stake(address, uint256);
  uint256 public constant threshold = 1 ether;

  receive() external payable {
    stake();
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), 'Contract has alredy been completed');
    _;
  }

  function stake() public payable {
    require(block.timestamp < deadline, 'Deadline has been reached');
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function getBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function withdraw(address _to) external notCompleted {
    require(openForWithdraw, 'Contract is not open for withdraw');
    (bool sent, ) = payable(_to).call{value: address(this).balance}('');
    require(sent, 'Failed to send Ether');
  }

  function execute() external notCompleted {
    require(block.timestamp > deadline, 'Deadline has not been reached yet');
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  function timeLeft() external view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }
}
