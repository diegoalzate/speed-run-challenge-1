// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */
    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract
    mapping(address => uint) liquidity;
    uint totalLiquidity;


    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address sender, string data, uint amountOfEth, uint amountOfTokens);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address sender, string data, uint amountOfEth, uint amountOfTokens);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(address sender, uint liquidityMinted, uint ethAdded,uint amountOfTokens);

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(address sender, uint amount, uint ethWithdrawn, uint tokenAmount);

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "Contract has already been initiated");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: init - transfer did not transact");
        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public view returns (uint256 yOutput) {
        uint xInputWithFee = xInput.mul(997);
        uint numerator = xInputWithFee.mul(yReserves);
        uint denominator = xInputWithFee.add(xReserves.mul(1000));
        return numerator / denominator;
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "Can not send 0 eth");
        uint amountOfTokensWithoutValue = address(this).balance.sub(msg.value);
        uint amountOfTokens = price(msg.value, amountOfTokensWithoutValue, token.balanceOf(address(this)));
        require(token.transfer(msg.sender, amountOfTokens), "Reverted swap.");
        emit EthToTokenSwap(msg.sender, "Eth to Balloons", msg.value, amountOfTokens);
        return amountOfTokens;
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");
        uint amountOfEth = price(tokenInput, token.balanceOf(address(this)), address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "Can not send tokens to contract");
        (bool sent, ) = msg.sender.call{value: amountOfEth}("");
        require(sent, "tokenToEth: revert in transferring eth to you!");
        emit TokenToEthSwap(msg.sender, "Balloons to ETH", ethOutput, tokenInput);
        return amountOfEth;
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Need to deposit more than 0");
        uint amountOfEth = msg.value;
        uint ethReserve = address(this).balance.sub(amountOfEth);
        uint amountOfTokens = (amountOfEth.mul(token.balanceOf(address(this)) / ethReserve)).add(1);
        uint liquidityMinted = msg.value.mul(totalLiquidity / ethReserve);
        liquidity[msg.sender] += liquidityMinted;
        require(token.transferFrom(msg.sender, address(this), amountOfTokens), "Can not send tokens to contract");
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, amountOfTokens);
        return amountOfTokens;
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
     */
    function withdraw(uint256 amount) public returns (uint256 eth_amount, uint256 token_amount) {
        require(liquidity[msg.sender] >= amount, "you dont have enough liquidity");
        uint ethAmount = amount.mul(address(this).balance/ totalLiquidity);
        uint tokenAmount = amount.mul(token.balanceOf(address(this)) / totalLiquidity);
        liquidity[msg.sender] -= amount;
        require(token.transferFrom(address(this), msg.sender, tokenAmount), "Can not send tokens to contract");
        (bool sent, ) = payable(msg.sender).call{value: ethAmount}("");
        require(sent, "withdraw: eth was not able to be sent to user");
        emit LiquidityRemoved(msg.sender, amount, ethAmount, tokenAmount);
        return (ethAmount, tokenAmount);
    }
}
