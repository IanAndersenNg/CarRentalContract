// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarRental {
   struct Car {
    string carPlate;
    bool isDamaged;
    bool isRented;
    uint256 deposit;
    uint256 price;
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
    event CarAdded(string carPlate, uint256 deposit, uint256 price);
    event CarDetails(string carPlate, bool isDamaged, bool isRented, uint256 deposit, uint256 price, address renterAddress);
    event CarRented(string carPlate, address indexed renter);
    event CarReturned(string carPlate, address indexed renter, bool isDamaged, uint256 refundAmount, uint256 damageFee);

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

    modifier carExists(string memory carPlate) {
        Car storage car = carMap[carPlate];
        // we check if car exists using the following requirement:
        // in the code above, an empty car struct with default values is constructed
        // so we can check if a valid car exists by checking its deposit and price
        require(car.deposit > 0 && car.price > 0, "Car does not exist.");
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
        uint256 price
    ) external onlyOwner {
        require(deposit > 0 && price > 0, "Car must have a deposit and price.");
        // TODO - car plate uniqueness check?
        Car storage newCar = carMap[carPlate];
        newCar.carPlate = carPlate;
        newCar.deposit = deposit;
        newCar.price = price;
        newCar.isRented = false;
        newCar.isDamaged = false;
        newCar.renterAddress = address(0);
        carPlates.push(carPlate);
        emit CarAdded(carPlate, deposit, price);
    }

    function getAllCars() external {
        require(carPlates.length > 0, "No cars are available.");
        for (uint256 i = 0; i < carPlates.length; i++) {
            Car storage car = carMap[carPlates[i]];
            emit CarDetails(
                car.carPlate, 
                car.isDamaged, 
                car.isRented, 
                car.deposit, 
                car.price,
                car.renterAddress
            );
        } 
    }

    function isCarAvailable(string memory carPlate) public view carExists(carPlate) returns (bool) {
        Car storage car = carMap[carPlate];
        return !car.isRented;
    }
    
    function rentCar(string memory carPlate) external carExists(carPlate) {
        Car storage car = carMap[carPlate];
        require(!car.isRented, "Car is already rented.");
        require(car.deposit + car.price <= token.balanceOf(msg.sender), "You have insufficient CRS balance to rent this car");
        
        // transfer tokens (price + deposit) from the renter to the contract
        uint totalRental = car.deposit + car.price;
        token.transferFrom(msg.sender, wallet, totalRental);
        
        car.isRented = true;
        car.renterAddress = msg.sender;
        
        emit CarRented(carPlate, msg.sender);
    }



    function damageCheck() private view returns (bool) {
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Replaced block.difficulty
            msg.sender
        ))) % 100; // A number between 0-99
        return random < 7; // Set damage probability to 7%
    }




    function returnCar(string memory carPlate) external {
        Car storage car = carMap[carPlate];

        require(car.isRented, "Car is not rented.");
        require(car.renterAddress == msg.sender, "You are not the renter of this car.");
        bool isDamaged = damageCheck();

        // Initialize the refund amount to the deposit
        uint refundAmount = car.deposit;
        uint damageFee = 0;

        if (isDamaged) {
            // Calculate the damage fee as 50% of the rental price
            damageFee = car.price / 2;
            refundAmount -= damageFee;

            token.transferFrom(msg.sender, wallet, damageFee);
            car.isDamaged = true;
            
        } else {
            car.isDamaged = false;
        }

        token.transfer(msg.sender, refundAmount);

        car.isRented = false;          
        car.renterAddress = address(0); 

        emit CarReturned(carPlate, msg.sender, isDamaged, refundAmount, damageFee);
    }




}