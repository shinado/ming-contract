// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Constants.sol";
import "./SqrtMath.sol";
import "./Address.sol";
// import "./INonfungiblePositionManager.sol";
import "hardhat/console.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/base/PoolInitializer.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20{
    function deposit() external payable;
    function withdraw(uint) external;
}

contract Funding is IERC721Receiver{

    event LogData(string message);

    function log(string memory message) public {
        emit LogData(message);
    }

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
    bool private fundingIsOver = false;
    INonfungiblePositionManager private nonfungiblePositionManager = INonfungiblePositionManager(Address.UNIV3_POS_MANAGER);

    IUniswapV3Factory private v3Factory = IUniswapV3Factory(Address.UNIV3_FACTORY);
    IUniswapV3Pool private pool;

    uint24 constant fee = 3000;
    int24 tickSpacing;
    IWETH weth;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public /* immutable */ i_owner;

    uint private endTime;
    uint private fundRaised;


// int24 private TICK_SPACING_MULTIPLIER = 1;
// uint private DIVIDER = 1000000000;
// new position minted: 3000000000, 16393208619879433559

// int24 private TICK_SPACING_MULTIPLIER = 10;
// uint private DIVIDER = 100000000;
// new position minted: 30000000000, 20084378293542997594

// int24 private TICK_SPACING_MULTIPLIER = 10;
// uint private DIVIDER = 1000000000;
// new position minted: 3000000000, 13062035016748284206

// int24 private TICK_SPACING_MULTIPLIER = 100;
// uint private DIVIDER = 100000000;
// new position minted: 30000000000, 17016637491265618513

// int24 private TICK_SPACING_MULTIPLIER = 2;
// uint private DIVIDER = 100000000;
// new position minted: 30000000000, 45086577608060017841

// int24 private TICK_SPACING_MULTIPLIER = 100;
// uint private DIVIDER = 10000000;
// new position minted: 300000000000, 1494779771482091264

// int24 private TICK_SPACING_MULTIPLIER = 1000;
// uint private DIVIDER = 1000000;
// new position minted: 3000000000000, 14858567203810165621

// int24 private TICK_SPACING_MULTIPLIER = 10000;
// uint private DIVIDER = 100000;
// new position minted: 30000000000000, 995106226754077155

// Error: VM Exception while processing transaction: reverted with reason string 'T'
// int24 private TICK_SPACING_MULTIPLIER = 100000;
// uint private DIVIDER = 10000;

    int24 private TICK_SPACING_MULTIPLIER = 2;
    uint private DIVIDER = 100000000;
    
    constructor(address _addressOfMing, uint _endTime) {
        addressOfMing = _addressOfMing;
        i_owner = msg.sender;
        weth = IWETH(Address.WETH);
        endTime = _endTime;
    }

    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        // get position information
        // _createDeposit(operator, tokenId);
        return this.onERC721Received.selector;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function concatString(string memory str1, string memory str2) public pure returns (string memory) {
        return string(abi.encodePacked(str1, str2));
    }

    function concatStringWithUint(string memory str, uint num) public pure returns (string memory) {
        return string(abi.encodePacked(str, num));
    }

    function fund() public payable {
        log("calling fund()");
        uint256 ETHAmount = msg.value;
        require(ETHAmount > 0, "fund must > zero");
        log(concatStringWithUint("ETH balance: ", ETHAmount));

        require(
            block.timestamp < endTime, 
            "funding has ended"
        );

        uint256 balanceBefore = weth.balanceOf(address(this));

        if (ETHAmount != 0) {
            //balanceOf[msg.sender] = msg.value
            weth.deposit{ value: ETHAmount }();
            weth.transfer(address(this), ETHAmount);
        }

        uint256 balanceNow = weth.balanceOf(address(this));
        log(concatStringWithUint("balance of WETH now: ", balanceNow));

        require(
            balanceNow - balanceBefore == ETHAmount,
            "Ethereum not deposited");

        if(!addressToAmountFunded[msg.sender].exists){
            funders.push(msg.sender);
            addressToAmountFunded[msg.sender].exists = true;

            console.log("funders.length = %s", funders.length);
        }

        addressToAmountFunded[msg.sender].amount += msg.value;

        fundRaised += msg.value;
        log(concatStringWithUint("fundRaised: ", fundRaised));
    }

    function getCurrentAmountFunded(address addr) public view returns (uint256){
        return addressToAmountFunded[addr].amount;
    }

    function getAmountFunded(address addr) public view returns (uint256){
        return addressToAmountFunded[addr].amount;
    }

    modifier onlyOwner {
        require(
            msg.sender == i_owner,
            "not owner"
        );
        _;
    }

    function onFundingOver() public onlyOwner{
        require(!fundingIsOver, "Funding over has been called.");
        fundingIsOver = true;

        console.log("------------ begin of contract method onFundingOver() ------------");
        console.log("fundRaised: %s", fundRaised);

        IERC20 ming = IERC20(addressOfMing);
        uint256 totalSupply = ming.totalSupply();

        uint256 amountOfMing = (totalSupply * 50) / 100;
        console.log("amount of MING to  uniswap: %s", amountOfMing);

        if (fundRaised == 0) {
            //zero raised
            //burn
            console.log("zero raised, burn all tokens");
            ming.transfer(0x4444444444444444444444444444444444444444, amountOfMing);
        }else{
            sendMingToFunder(amountOfMing);
            sendToUniswapV2(fundRaised, amountOfMing);
        }

        console.log("------------ end of contract method onFundingOver() ------------");
    }


    function sendToUniswapV2(uint256 amountOfETH, uint256 amountOfMing) private{
        if(tokenId == 0){
            // wtf require(key.token0 < key.token1)?
            // the number is around 1.2996 to make mint this position. why?
            if(Address.WETH < addressOfMing){
                console.log("init pool");
                uint160 sqrtPriceX96 = encodePriceSqrt(amountOfMing/DIVIDER, amountOfETH/DIVIDER);
                address poolAddress = nonfungiblePositionManager.createAndInitializePoolIfNecessary(
                    Address.WETH, addressOfMing, fee, sqrtPriceX96);
                pool = IUniswapV3Pool(poolAddress);

                tickSpacing = pool.tickSpacing();
                (uint256 _tokenId, , , ) = mintNewPosition(amountOfETH/DIVIDER, amountOfMing/DIVIDER);
                tokenId = _tokenId;

                increaseLiquidityCurrentRange(tokenId, amountOfETH-amountOfETH/DIVIDER, amountOfMing-amountOfMing/DIVIDER);
            }else{
                console.log("init pool reversed");

                uint160 sqrtPriceX96 = encodePriceSqrt(amountOfETH/DIVIDER, amountOfMing/DIVIDER);
                address poolAddress = nonfungiblePositionManager.createAndInitializePoolIfNecessary(addressOfMing, Address.WETH, fee, sqrtPriceX96);
                pool = IUniswapV3Pool(poolAddress);

                tickSpacing = pool.tickSpacing();
                (uint256 _tokenId, , , ) = mintNewPosition(amountOfMing/DIVIDER, amountOfETH/DIVIDER);
                tokenId = _tokenId;

                increaseLiquidityCurrentRange(tokenId, amountOfMing-amountOfMing/DIVIDER, amountOfETH-amountOfETH/DIVIDER);
            }
            console.log("token0: %s -> token1: %s, tick: ", 
                    pool.token0(), pool.token1());
            console.logInt(tickSpacing);
        }
    }

    function sendToUniswap(uint256 amountOfETH, uint256 amountOfMing) private{
        if(tokenId == 0){
            // wtf require(key.token0 < key.token1)?
            // the number is around 1.2996 to make mint this position. why?
            if(Address.WETH < addressOfMing){
                //testing
                // pool = IUniswapV3Factory(Address.UNIV3_FACTORY).getPool(Address.WETH, addressOfMing, fee);

                console.log("init pool");
                /*
                 * init pool
                    balance of token0 and token1 -> 3000000000000000000, 222222222222222000000000000000000
                    amount to mint new position  -> 3000000000000000000, 222222222222222000000000000000000
                    current tick: 
                    10858
                    lower*upper tick 
                    10680
                    10920
                    new position minted: 3000000000000000000, 25559352082992436084
                    new balance of token0 and token1 -> 0, 222222222222196440647917007563916
                 */
                uint160 sqrtPriceX96 = encodePriceSqrt(amountOfMing, amountOfETH);
                //in the code require(token0 < token1);
                address poolAddress = nonfungiblePositionManager.createAndInitializePoolIfNecessary(
                    Address.WETH, addressOfMing, fee, sqrtPriceX96);
                pool = IUniswapV3Pool(poolAddress);

                // pool = IUniswapV3Pool(
                //     v3Factory.createPool(Address.WETH, addressOfMing, fee)
                // );
                // pool.initialize(sqrtPriceX96);
                tickSpacing = pool.tickSpacing();
                (uint256 _tokenId, , , ) = mintNewPosition(amountOfETH, amountOfMing);
                tokenId = _tokenId;
            }else{
                console.log("init pool reversed");

                /*
                 * init pool reversed
                    balance of token0 and token1 -> 222222222222222000000000000000000, 3000000000000000000
                    amount to mint new position  -> 222222222222222000000000000000000, 3000000000000000000
                    current tick: 
                    -319377
                    lower*upper tick 
                    -319440
                    -319200
                    new position minted: 222222222222221881972731889480568, 1074641434982737006
                 */
                uint160 sqrtPriceX96 = encodePriceSqrt(amountOfETH, amountOfMing);
                address poolAddress = nonfungiblePositionManager.createAndInitializePoolIfNecessary(addressOfMing, Address.WETH, fee, sqrtPriceX96);
                pool = IUniswapV3Pool(poolAddress);

                // pool = IUniswapV3Pool(
                //     v3Factory.createPool(addressOfMing, Address.WETH, fee)
                // );
                // pool.initialize(sqrtPriceX96);
                tickSpacing = pool.tickSpacing();
                (uint256 _tokenId, , , ) = mintNewPosition(amountOfMing, amountOfETH);
                tokenId = _tokenId;
            }

            console.log("token0: %s -> token1: %s, tick: ", 
                    pool.token0(), pool.token1());
            console.logInt(tickSpacing);
        }

        // increaseLiquidityCurrentRange(tokenId, amountOfETH, amountOfMing);
    }

    function mintNewPosition(uint256 amountOf0, uint256 amountOf1)
        private  
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        console.log("balance of ETH and MING -> %s, %s", 
                IERC20(pool.token0()).balanceOf(address(this)), IERC20(pool.token1()).balanceOf(address(this)));
        console.log("amount to mint new position  -> %s, %s", amountOf0, amountOf1);

        // I approve nonfungiblePositionManager to use amountOfETH, 
        // so that nonfungiblePositionManager can call transferFrom(fundingContract, anotherAddress, amountOfMing)
        IERC20(pool.token0()).approve(address(nonfungiblePositionManager), amountOf0);
        IERC20(pool.token1()).approve(address(nonfungiblePositionManager), amountOf1);

        // Get tick spacing
        // tick will affect mint amounts!!!!
        /**
         * get a very close result using tickSpacing * 100
         * amount to mint new position  -> 222222222222222000000000000000000, 3000000000000000000
                    new position minted:   222222222222221929391058705292069, 2951656404737797766
                    new balance of token0 and token1 ->    70608941294707931,   48343595262202234
         */
        (, int24 curTick, , , , , ) = pool.slot0();
        console.log("current tick: ");
        console.logInt(curTick);
        curTick = curTick - (curTick % tickSpacing);
        int24 lowerTick = curTick - (tickSpacing * TICK_SPACING_MULTIPLIER); //we don't really care about slipage so set tick high
        int24 upperTick = curTick + (tickSpacing * TICK_SPACING_MULTIPLIER);
        require(curTick % tickSpacing == 0, 'tick error');

        console.log("lower*upper tick ");
        console.logInt(lowerTick);
        console.logInt(upperTick);
        
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: pool.token0(),
                token1: pool.token1(),
                fee: poolFee,
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: amountOf0, 
                amount1Desired: amountOf1, 
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        // Note that the pool defined by DAI/USDC and fee tier 0.3% must already be 
        // created and initialized in order to mint
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
        console.log("new position minted: %s, %s", amount0, amount1);

        // Remove allowance and refund in both assets.
        // do not need to refund
        if (amount0 < amountOf0) {
            TransferHelper.safeApprove(pool.token0(), address(nonfungiblePositionManager), 0);
            // uint256 refund0 = amountOfETH - amount0;
            // console.log("refund ETH %s", refund0);
            // TransferHelper.safeTransfer(Address.WETH, msg.sender, refund0);
        }
        if (amount1 < amountOf1) {
            TransferHelper.safeApprove(pool.token1(), address(nonfungiblePositionManager), 0);
            // uint256 refund1 = amountOfMing - amount1;
            // console.log("refund MING %s", refund1);
            // TransferHelper.safeTransfer(addressOfMing, msg.sender, refund1);
        }

        console.log("new balance of ETH and MING -> %s, %s", 
                IERC20(pool.token0()).balanceOf(address(this)), IERC20(pool.token1()).balanceOf(address(this)));

        /**
         * amount to mint new position: 300000000000000000 -> 22222222222222200000000000000000
            balance of WETH and Ming -> 3000000000000000000, 222222222222222000000000000000000
                   new position minted: 300000000000000000,  2555935208299243609
        new balance of WETH and Ming -> 444064791700756391, 222222222222221700000000000000000
                            which is:   WETH-amount1,       MING-amount0
                            should be:  WETH-amount0,       WETH-amount1
         */
    }

    /// @notice Increases liquidity in the current range
    /// @dev Pool must be initialized already to add liquidity
    /// @param tokenId The id of the erc721 token
    /// @param amount0 The amount to add of token0
    /// @param amount1 The amount to add of token1
    function increaseLiquidityCurrentRange(
        uint256 tokenId,
        uint256 amountAdd0,
        uint256 amountAdd1
    )
        private 
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) {

        // TransferHelper.safeTransferFrom(deposits[tokenId].token0, msg.sender, address(this), amountAdd0);
        // TransferHelper.safeTransferFrom(deposits[tokenId].token1, msg.sender, address(this), amountAdd1);
        // TransferHelper.safeApprove(deposits[tokenId].token0, address(nonfungiblePositionManager), amountAdd0);
        // TransferHelper.safeApprove(deposits[tokenId].token1, address(nonfungiblePositionManager), amountAdd1);

        // TransferHelper.safeTransferFrom(pool.token0(), msg.sender, address(this), amountAdd0);
        // TransferHelper.safeTransferFrom(pool.token1(), msg.sender, address(this), amountAdd1);
        TransferHelper.safeApprove(pool.token0(), address(nonfungiblePositionManager), amountAdd0);
        TransferHelper.safeApprove(pool.token1(), address(nonfungiblePositionManager), amountAdd1);

        console.log("amount to increase liquidity: %s -> %s", amountAdd0, amountAdd1);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amountAdd0,
            amount1Desired: amountAdd1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);

        console.log("actual amounts: %s -> %s", amount0, amount1);
    }

    // function _createDeposit(address owner, uint256 tokenId) internal {
    //     // (, , address token0, address token1, , , , uint128 liquidity, , , , ) =
    //     (address token0, address token1,uint128 liquidity) =
    //         nonfungiblePositionManager.positions1(tokenId);
    //     // set the owner and data for position
    //     // operator is msg.sender
    //     deposits[tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});
    // }

    function sendMingToFunder(uint256 totalAmountOfMing) private{
        console.log("------------ begin of contract method sendMingToFunder() ------------");
        IERC20 ming = IERC20(addressOfMing);
        uint256 balanceOfETH = weth.balanceOf(address(this));
        console.log("balance of WETH: %s", balanceOfETH);

        address[] memory currentFunders = funders;
        console.log("currentFunders.length: %s", currentFunders.length);

        for (uint256 funderIndex=0; funderIndex < currentFunders.length; funderIndex++){
            address funder = currentFunders[funderIndex];
            uint256 amountETH = addressToAmountFunded[funder].amount;

            uint256 transferAmount = totalAmountOfMing * amountETH / balanceOfETH;

            // msg.sender is this funding contract
            ming.transfer(funder, transferAmount);

            console.log("balance of funder: %s", ming.balanceOf(funder));

            // do not need to clear map
            // addressToAmountFunded[funder].amount = 0;
            // addressToAmountFunded[funder].exists = false;
        }

        // do not clear funders
        // funders = new address[](0);
        console.log("------------ end of contract method sendMingToFunder() ------------");


        /**
         * new balance of WETH and Ming -> 2999997444064791700,  222222222222221999999700000000000
             amount to increase liquidity: 300000000000000000 -> 22222222222222200000000000000000
          actual amounts :                 300000000000000000 -> 2555935208299243609
         */
    }
    
}