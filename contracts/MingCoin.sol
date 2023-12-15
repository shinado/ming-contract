// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MingCoin is ERC20 {

    // address private addressOfSBT;
    mapping(string => address) private name2address;
    mapping(address => string) private address2name;

    constructor() ERC20("Ming Coin", "MING") {
        // addressOfSBT = _addressOfSBT;
        _mint(msg.sender, 444_444_444_444_444 * 10 ** 18);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        console.log("calling Ming.transfer(%s), from %s to %s", amount, msg.sender, recipient);
        return super.transfer(recipient, amount);
    }

    function burn(string memory recipient, uint256 amount) public returns (address){
        address addr = stringToAddress(recipient);
        transfer(addr, amount);

        name2address[recipient] = addr;
        address2name[addr] = recipient;

        return addr;
        // TODO transfer SBT to sender
        // IERC721 sbt = IERC721(addressOfSBT);
        // sbt.mint(recipient, 1);
    }

    function getAddressByName(string calldata recipient) public view returns (address){
        return name2address[recipient];
    }

    function getNameByAddress(address addr) public view returns (string memory){
        return address2name[addr];
    }
        
    function stringToAddress(string memory inputString) private pure returns (address) {
        // Hash the input string
        bytes32 hash = keccak256(abi.encodePacked(inputString));

        // Convert hash and '0x44444444' to bytes
        bytes memory hashBytes = abi.encodePacked(hash);
        // bytes memory additionalString = "DDDD";
        bytes memory combinedBytes = new bytes(20);

        uint k = 0;
        for(uint i=0;i<4;i++) combinedBytes[k++] = 'D';

        // Concatenate bytes
        // for (uint i = 0; i < additionalString.length; i++) combinedBytes[k++] = additionalString[i];
        for (uint i = 0; k < 20; i++) combinedBytes[k++] = hashBytes[i];

        // Convert the combined bytes to address
        // Note: This might not result in a valid address
        return bytesToAddress(combinedBytes);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
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

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint i = 0; i < 20; i++) {
            stringBytes[2+i*2] = hexBytes[uint8(addressBytes[i] >> 4)];
            stringBytes[3+i*2] = hexBytes[uint8(addressBytes[i] & 0x0f)];
        }

        return string(stringBytes);
    }

    function addressToKeccak256Hash(address _addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(toAsciiString(_addr)));
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}