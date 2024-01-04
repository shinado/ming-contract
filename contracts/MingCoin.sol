// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MingCoin is ERC20 {

    struct KV {
        string key;
        uint256 value;
    }

    struct Profile {
        mapping(string => uint) valueMap;
        mapping(string => bool) keyExists;
        string[] keys;
        bool exists;
    }

    struct Burning {
        string name;
        string displayName;
        uint256 amount;
        bool exists;
    }

    mapping(address => Profile) private bannerMap;
    mapping(address => Profile) private portraitMap;
    mapping(address => Profile) private bioMap;
    mapping(address => Burning) private addressMap;
    mapping(string => address) private name2Address;
    // Array to store the keys of the mapping
    address[] private addresses;

    constructor() ERC20("Ming Coin v0.0.5", "MING") {
        // addressOfSBT = _addressOfSBT;
        _mint(msg.sender, 444_444_444_444_444 * 10 ** 18);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        console.log(
            "calling Ming.transfer(%s), from %s to %s",
            amount,
            msg.sender,
            recipient
        );
        return super.transfer(recipient, amount);
    }

    function getBurningList() public view returns (Burning[] memory) {
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
            kvs[i] = KV({key: key, value: selectedProfile.valueMap[key]});
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

        if (amount > 0) {
            transfer(addr, amount);
            // do not add this amount to it
            // addressMap[addr].amount += amount;
        }

        if (_type == 1) {
            if (bannerMap[addr].keyExists[url] == false) {
                bannerMap[addr].keyExists[url] = true;
                bannerMap[addr].keys.push(url);
            }

            bannerMap[addr].valueMap[url] += amount;
        } else if (_type == 2) {
            if (portraitMap[addr].keyExists[url] == false) {
                portraitMap[addr].keyExists[url] = true;
                portraitMap[addr].keys.push(url);
            }

            portraitMap[addr].valueMap[url] += amount;
        } else if (_type == 3) {
            if (bioMap[addr].keyExists[url] == false) {
                bioMap[addr].keyExists[url] = true;
                bioMap[addr].keys.push(url);
            }
            
            bioMap[addr].valueMap[url] += amount;
        } else {
            revert("Invalid type");
        }
    }

    function burn(
        string memory displayName,
        string memory recipient,
        uint256 amount
    ) public returns (address) {
        address addr = stringToAddress(recipient);
        transfer(addr, amount);

        if (addressMap[addr].exists == false) {
            addressMap[addr].exists = true;
            addressMap[addr].displayName = displayName;
            addressMap[addr].name = recipient;
            addresses.push(addr);
        }
        addressMap[addr].amount += amount;

        name2Address[recipient] = addr;
        return addr;
        // TODO transfer SBT to sender
        // IERC721 sbt = IERC721(addressOfSBT);
        // sbt.mint(recipient, 1);
    }

    function getAddressByName(
        string calldata recipient
    ) public view returns (address) {
        return name2Address[recipient];
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

    function startsWith44444444(address _addr) public pure returns (bool) {
        string memory addrStr = toAsciiString(_addr);
        bytes memory prefixBytes = bytes("0x44444444");

        for (uint i = 0; i < 8; i++) {
            if (bytes(addrStr)[i] != prefixBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function toAsciiString(address _addr) public pure returns (string memory) {
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
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(toAsciiString(_addr)));
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
