// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Constants.sol";
import "./SqrtMath.sol";
import "./Address.sol";
import "hardhat/console.sol";

import "./Address.sol";
import "hardhat/console.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@uniswap/v3-periphery/contracts/base/PoolInitializer.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract MingCoin is ERC20 {
    struct KV {
        string key;
        uint256 value;
    }

    struct KeyValue {
        uint256 value;
        bool exists;
    }

    struct Profile {
        mapping(string => KeyValue) valueMap;
        string[] keys;
        bool exists;
    }

    struct BurningInfo {
        address from;
        uint256 amount;
        string message;
    }

    struct Burning {
        address addr;
        string name;
        uint256 amount;
        bool exists;
    }

    mapping(address => Profile) private bannerMap;
    mapping(address => Profile) private portraitMap;
    mapping(address => Profile) private bioMap;
    mapping(address => Burning) private addressMap;
    mapping(address => BurningInfo[]) private burningMap;
    mapping(string => address) private name2Address;
    // Array to store the keys of the mapping
    address[] private addresses;

    uint256 private constant MAX = 444_444_444_444 * 10 ** 18;
    uint256 private constant MINT_AMOUNT = 444_444_000_000 * 10 ** 12; //444_444.444_444
    uint256 private constant EXCHANGE_RATE = 106_666_666; //41.66 ETH for whole supply

    uint256 private total = 0;
    address public /* immutable */ i_owner;
    uint24 public constant poolFee = 3000;

    INonfungiblePositionManager private nonfungiblePositionManager = INonfungiblePositionManager(Address.UNIV3_POS_MANAGER);

    IUniswapV3Factory private v3Factory = IUniswapV3Factory(Address.UNIV3_FACTORY);
    IUniswapV3Pool private pool;

    uint24 constant fee = 3000;
    int24 tickSpacing;


    //version 0.1.0 changed to free mint
    //version 0.1.2 added batch mint
    //version 0.1.3 added burning message
    constructor() ERC20("Ming Coin v0.1.3", "MING") {
        // addressOfSBT = _addressOfSBT;
        // _mint(msg.sender, 444_444_444_444_444 * 10 ** 18);
        i_owner = msg.sender;
    }

    function maxSupply() public pure returns (uint256) {
        return MAX;
    }

    function totalMinted() public view returns (uint256) {
        return total;
    }

    function isMintOver() public view returns (bool) {
        return total >= MAX;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = payable(i_owner).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    //free mint
    //should we keep it?
    function mint() public returns (uint256) {
        require(total < MAX, "Mint finished");

        if (total + MINT_AMOUNT > MAX) {
            uint256 actualAmount = MAX - total;
            _mint(msg.sender, actualAmount);
            total += actualAmount;

            return actualAmount;
        } else {
            _mint(msg.sender, MINT_AMOUNT);
            total += MINT_AMOUNT;
            return MINT_AMOUNT;
        }
    }

    function balanceToMint() public view returns (uint256) {
        return MAX - total;
    }

    function batchMint() public payable {
        uint256 ETHAmount = msg.value;
        console.log("ETHAmount: ");
        console.log(ETHAmount);

        require(ETHAmount > 0, "fund must > zero");

        uint256 amountOfMing = ETHAmount * EXCHANGE_RATE;
        require(balanceToMint() >= amountOfMing, "Not enough MING to mint");

        //send amountOfMing to funder
        _mint(msg.sender, amountOfMing);
        total += amountOfMing;
    }


    //avoid calling this function as the array grows larger
    function getBurningList() public view returns (Burning[] memory) {
        if (addresses.length > 10000) {
            revert(
                "Avoid calling this function as the addresses grow too large"
            );
        }

        Burning[] memory burnings = new Burning[](addresses.length);
        for (uint i = 0; i < addresses.length; i++) {
            burnings[i] = addressMap[addresses[i]];
        }
        return burnings;
    }

    function getProfileList(
        uint _type,
        address addr
    ) public view returns (KV[] memory) {
        Profile storage selectedProfile;

        if (_type == 1) {
            selectedProfile = bannerMap[addr];
        } else if (_type == 2) {
            selectedProfile = portraitMap[addr];
        } else if (_type == 3) {
            selectedProfile = bioMap[addr];
        } else {
            revert("Invalid type");
        }

        KV[] memory kvs = new KV[](selectedProfile.keys.length);
        for (uint i = 0; i < selectedProfile.keys.length; i++) {
            string memory key = selectedProfile.keys[i];
            kvs[i] = KV({key: key, value: selectedProfile.valueMap[key].value});
        }

        return kvs;
    }

    function updateProfile(
        uint _type,
        address addr,
        string memory url,
        uint amount
    ) public {
        require(addressMap[addr].exists == true, "Address not exists");
        require(_type >= 1 && _type <= 3, "Invalid type");

        Profile storage profile;
        if (_type == 1) {
            profile = bannerMap[addr];
        } else if (_type == 2) {
            profile = portraitMap[addr];
        } else if (_type == 3) {
            profile = bioMap[addr];
        }

        if (amount > 0) {
            transfer(addr, amount);
            // do not add this amount to it
            // addressMap[addr].amount += amount;
        }

        KeyValue storage keyValue = profile.valueMap[url];
        if (!keyValue.exists) {
            keyValue.exists = true;
            profile.keys.push(url);
        }

        keyValue.value += amount;
    }

    function _burnToAddress(
        address addr,
        uint256 amount,
        string memory message
    ) private{
        transfer(addr, amount);
        addressMap[addr].amount += amount;

        burningMap[addr].push(
            BurningInfo({from: msg.sender, amount: amount, message: message})
        );
    }

    function burnToAddress(
        address addr,
        uint256 amount,
        string memory message
    ) public {
        require(addressMap[addr].exists == true, "Address not exists");

        _burnToAddress(addr, amount, message);
    }

    function getBurningHistory(
        address addr
    ) public view returns (BurningInfo[] memory) {
        return burningMap[addr];
    }

    function burn(
        string memory recipient,
        uint256 amount,
        string memory message
    ) public returns (address) {
        address addr = stringToAddress(recipient);

        if (addressMap[addr].exists == false) {
            addressMap[addr].exists = true;
            addressMap[addr].name = recipient;
            addressMap[addr].addr = addr;
            addresses.push(addr);
        }
        _burnToAddress(addr, amount, message);

        return addr;
    }

    function getAddressByName(
        string calldata recipient
    ) public view returns (address) {
        address addr = name2Address[recipient];
        if (addr == address(0)) {
            return stringToAddress(recipient);
        }

        return addr;
    }

    function getNameByAddress(
        address addr
    ) public view returns (string memory) {
        return addressMap[addr].name;
    }

    // A method to return a Burning struct
    function getBaseProfile(address addr) public view returns (Burning memory) {
        return addressMap[addr];
    }

    function stringToAddress(
        string memory inputString
    ) private pure returns (address) {
        // Hash the input string
        bytes32 hash = keccak256(abi.encodePacked(inputString));

        // Convert hash and '0x44444444' to bytes
        bytes memory hashBytes = abi.encodePacked(hash);
        // bytes memory additionalString = "DDDD";
        bytes memory combinedBytes = new bytes(20);

        uint k = 0;
        for (uint i = 0; i < 4; i++) combinedBytes[k++] = "D";

        // Concatenate bytes
        // for (uint i = 0; i < additionalString.length; i++) combinedBytes[k++] = additionalString[i];
        for (uint i = 0; k < 20; i++) combinedBytes[k++] = hashBytes[i];

        // Convert the combined bytes to address
        // Note: This might not result in a valid address
        return bytesToAddress(combinedBytes);
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function startsWith44444444(address _addr) private pure returns (bool) {
        string memory addrStr = toAsciiString(_addr);
        bytes memory prefixBytes = bytes("0x44444444");

        for (uint i = 0; i < 8; i++) {
            if (bytes(addrStr)[i] != prefixBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function toAsciiString(address _addr) private pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(_addr);
        bytes memory hexBytes = "0123456789abcdef";
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = "0";
        stringBytes[1] = "x";

        for (uint i = 0; i < 20; i++) {
            stringBytes[2 + i * 2] = hexBytes[uint8(addressBytes[i] >> 4)];
            stringBytes[3 + i * 2] = hexBytes[uint8(addressBytes[i] & 0x0f)];
        }

        return string(stringBytes);
    }

    function addressToKeccak256Hash(
        address _addr
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(toAsciiString(_addr)));
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    modifier onlyOwner {
        require(
            msg.sender == i_owner,
            "not owner"
        );
        _;
    }

}