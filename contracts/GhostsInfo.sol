// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./MingCoin.sol";

contract GhostsInfo{

    // struct Vote {
    //     string value;
    //     uint256 votes;
    // }

    // mapping(address => Vote) private addressToPortrait;
    // mapping(address => Vote) private addressToDisplayName;
    // address private addressOfMing;

    // constructor(address _addressOfMing){
    //     addressOfMing = _addressOfMing;
    // }

    // function voteDisplayName(address addr, uint256 amount, string memory displayName) public {
    //     MingCoin ming = MingCoin(addressOfMing);
    //     (bool callSuccess) = ming.transfer(addr, amount);
    //     require(callSuccess, "Call failed");

    //     addressToDisplayName[addr].value = displayName;
    //     addressToDisplayName[addr].votes += amount;
    // }

    // function votePortrait(address addr, uint256 amount, string memory url) public{
    //     MingCoin ming = new MingCoin();
    //     (bool callSuccess) = ming.transfer(addr, amount);
    //     require(callSuccess, "Call failed");

    //     addressToPortrait[addr].value = url;
    //     addressToPortrait[addr].votes += amount;
    // }

    // function getDisplayName(address addr) public view returns (string memory) {
    //     uint highestVotes = 0;
    //     string memory winner;

    //     for (uint i = 0; i < addressToDisplayName.length; i++) {
    //         if (addressToDisplayName[i].votes > highestVotes) {
    //             highestVotes = addressToDisplayName[i].votes;
    //             winner = addressToDisplayName[i].value;
    //         }
    //     }

    //     return winner;
    // }

    // function getPortrait(address addr) public view returns (string memory) {
    //     uint highestVotes = 0;
    //     string memory winner;

    //     for (uint i = 0; i < addressToPortrait.length; i++) {
    //         if (addressToPortrait[i].votes > highestVotes) {
    //             highestVotes = addressToPortrait[i].votes;
    //             winner = addressToPortrait[i].value;
    //         }
    //     }

    //     return winner;
    // }

}