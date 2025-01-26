// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarRental {
   struct Car {
    string carPlate;
    bool isDamaged;
    bool isRented;
    uint256 deposit;
    address renterAddress;
   }

    // Global Variables
    address private immutable owner;
    mapping(string => Car) private carMap;
    string[] private carPlates;

    ERC20 public token;
    address payable public wallet;
    uint256 public amountRaised;

    // Events for logging
    event CarAdded(string carPlate, address renterAddress);
    event CarDetails(string carPlate, bool isDamaged, bool isRented, uint256 deposit, address renterAddress);

    constructor(ERC20 _token) {
        owner = msg.sender;
        wallet = payable (owner); 
        token = _token; 
    }

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the car rental owner can do this.");
        _;
    }

    // methods
    function buyTokens() public payable {
        uint256 numTokens = msg.value / 1 ether;
        amountRaised += msg.value;
        token.transferFrom(wallet, msg.sender, numTokens);
        wallet.transfer(msg.value);
    }

    function addCar(
        string memory carPlate,
        uint256 deposit,
        address renterAddress
    ) external onlyOwner {
        Car storage newCar = carMap[carPlate];
        newCar.carPlate = carPlate;
        newCar.deposit = deposit;
        newCar.isRented = false;
        newCar.isDamaged = false;
        newCar.renterAddress = renterAddress;    
        carPlates.push(carPlate);
        emit CarAdded(carPlate, renterAddress);
    }

    function getAllCars() external onlyOwner {
        for (uint256 i = 0; i < carPlates.length; i++) {
            Car storage car = carMap[carPlates[i]];
            emit CarDetails(
                car.carPlate, 
                car.isDamaged, 
                car.isRented, 
                car.deposit, 
                car.renterAddress
            );
        } 
    }

}