// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Constants.sol";
import "./SqrtMath.sol";
import "./Address.sol";
import "hardhat/console.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20{
    function deposit() external payable;
    function withdraw(uint) external;
}

contract SimpleFunding {

    struct Funds{
        uint256 amount;
        bool exists;
    }

    /// @notice Represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    uint24 public constant poolFee = 3000;

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    mapping(address => Funds) private addressToAmountFunded;
    address[] private funders;
    address private addressOfMing;
    uint256 private tokenId = 0;
    INonfungiblePositionManager private nonfungiblePositionManager = INonfungiblePositionManager(Address.UNIV3_POS_MANAGER);

    IUniswapV3Factory private v3Factory = IUniswapV3Factory(Address.UNIV3_FACTORY);
    IUniswapV3Pool private pool;

    uint24 constant fee = 3000;
    int24 tickSpacing;
    IWETH weth;


    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;

    struct FundingInfo{
        uint startTime;
        uint endTime;
        uint percent;
    }

    FundingInfo[] private fundingInfos;
    
    constructor(address _addressOfMing) {
        addressOfMing = _addressOfMing;
        i_owner = msg.sender;
        weth = IWETH(Address.WETH);

        //stage 1 -> 2023.7.1 - 2023.7.15, 2.5% -> 250,000,000
        //stage 2 -> 2023.8.1 - 2023.8.30, 7.5%
        //stage 3 -> 2023.10.1 - 2023.11.15, 12.5%
        //stage 4 -> 2023.12.1 - 2024.1.31, 17.5%
        fundingInfos.push(FundingInfo(1688140800, 1689350400, 250000000));

        console.log("nonfungiblePositionManager.name() ->");
        console.log(nonfungiblePositionManager.name());
    }


    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    //OnlyFundingTtime
    function fund() public payable {
        uint256 ETHAmount = msg.value;
        require(ETHAmount > 0, "fund must > zero");

        uint256 balanceBefore = weth.balanceOf(address(this));

        if (ETHAmount != 0) {
            //balanceOf[msg.sender] = msg.value
            weth.deposit{ value: ETHAmount }();
            weth.transfer(address(this), ETHAmount);
        }

        uint256 balanceNow = weth.balanceOf(address(this));
        console.log("balance of WETH now ");
        console.log(balanceNow);

        require(
            balanceNow - balanceBefore == ETHAmount,
            "Ethereum not deposited");

        if(!addressToAmountFunded[msg.sender].exists){
            funders.push(msg.sender);
            addressToAmountFunded[msg.sender].exists = true;
        }

        addressToAmountFunded[msg.sender].amount += msg.value;
    }

    function getAmountFunded(address addr) public view returns (uint256){
        return addressToAmountFunded[addr].amount;
    }
    
}