// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarRental {
   struct Car {
    string carPlate;
    bool isDamaged;
    uint256 deposit;
    address renterAddress;
   }

    // for car rental
    address private immutable owner;
    mapping(string => Car) private carMap;

    // for ICO
    ERC20 public token;
    address payable public wallet;
    uint256 public amountRaised;

    constructor(ERC20 _token) {
        owner = msg.sender;
        wallet = payable (owner); 
        token = _token; 
    }

    function buyTokens() public payable {
        uint256 numTokens = msg.value / 1 ether;
        amountRaised += msg.value;
        token.transferFrom(wallet, owner, numTokens);
        wallet.transfer(msg.value);
    }

    // will make more to add car into the car map

}