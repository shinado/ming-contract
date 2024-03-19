// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

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
        uint256 _type;
        bool exists;
    }

    struct Burning {
        address addr;
        string name;
        uint256 amount;
        bool exists;
    }

    mapping(address => Profile) public bannerMap;
    mapping(address => Profile) public portraitMap;
    mapping(address => Profile) public bioMap;
    mapping(address => Burning) public addressMap;
    mapping(string => address) public name2Address;
    // Array to store the keys of the mapping
    address[] public addresses;

    string constant VERSION = "v0.1.4";
    uint256 constant MAX_SUPPLY = 444_444_444_444 * 10 ** 18;
    uint256 constant MINT_AMOUNT = 444_444_000_000 * 10 ** 12; //444_444.444_444
    uint256 constant EXCHANGE_RATE = 106_666_666; // 41.66 ETH for whole supply

    address public /* immutable */ i_owner;

    event updateProfileEvent(address from, uint256 _type, string value, uint256 amount);
    event burnMing(address from, uint256 value, string message);

    modifier onlyOwner {
        require(
            msg.sender == i_owner,
            "not owner"
        );
        _;
    }

    constructor() ERC20("Ming Coin", "MING") {
        // addressOfSBT = _addressOfSBT;
        // _mint(msg.sender, 444_444_444_444_444 * 10 ** 18);
        i_owner = msg.sender;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(i_owner).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function mint() external payable {
        uint256 ETHAmount = msg.value;
        console.log("ETHAmount: ");
        console.log(ETHAmount);

        require(ETHAmount > 0, "fund must > zero");

        uint256 amountOfMing = ETHAmount * EXCHANGE_RATE;
        require(MAX_SUPPLY - totalSupply() >= amountOfMing, "Not enough MING to mint");

        // send amountOfMing to funder
        _mint(msg.sender, amountOfMing);
    }

    function getProfileList(
        uint _type,
        address addr
    ) external view returns (KV[] memory) {
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
        uint256 _type,
        address addr,
        string calldata url,
        uint256 amount
    ) external {
        require(addressMap[addr].exists, "Address not exists");
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
        }

        if (!profile.valueMap[url].exists) {
            profile.valueMap[url].exists = true;
            profile.keys.push(url);
        }

        profile.valueMap[url].value += amount;

        emit updateProfileEvent(addr, _type, url, amount);
    }

    function _burnToAddress(
        address addr,
        uint256 amount,
        string calldata message
    ) private {
        transfer(addr, amount);
        addressMap[addr].amount += amount;

        emit burnMing(addr, amount, message);
    }

    function burnToAddress(
        address addr,
        uint256 amount,
        string calldata message
    ) external {
        require(addressMap[addr].exists, "Address not exists");

        _burnToAddress(addr, amount, message);
    }

    function burn (
        string calldata recipient,
        uint256 amount,
        string calldata message
    ) external {
        address addr = stringToAddress(recipient);

        if (addressMap[addr].exists == false) {
            addressMap[addr].exists = true;
            addressMap[addr].name = recipient;
            addressMap[addr].addr = addr;
            addresses.push(addr);
        }
        _burnToAddress(addr, amount, message);
    }

    function getAddressByName(
        string calldata recipient
    ) external view returns (address) {
        address addr = name2Address[recipient];
        if (addr == address(0)) {
            return stringToAddress(recipient);
        }

        return addr;
    }

    function getNameByAddress(
        address addr
    ) external view returns (string memory) {
        return addressMap[addr].name;
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
}