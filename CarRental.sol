// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CarRental {
    enum State {Available, Unavailable}
    struct Car {
        string carPlate;
        State state;
        uint256 deposit;
        uint256 price;
        address user;
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
    event CarLog(string carPlate, string message);
    event CarDetails(string carPlate, State state, uint256 deposit, uint256 price, address user);

    event CarRented(string carPlate, address indexed user);
    event CarReturned(string carPlate, address indexed user, State state, uint256 refundAmount, uint256 damageFee);

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
        require(price > 2 && deposit > price / 2, "Car deposit must be larger than 50% of price and price > 2.");
        // TODO - car plate uniqueness check?
        Car storage newCar = carMap[carPlate];
        newCar.carPlate = carPlate;
        newCar.deposit = deposit;
        newCar.price = price;
        newCar.state = State.Available;
        newCar.user = owner;
        carPlates.push(carPlate);
        emit CarAdded(carPlate, deposit, price);
    }

    function getAllCars() external {
        require(carPlates.length > 0, "No cars are available.");
        for (uint256 i = 0; i < carPlates.length; i++) {
            Car storage car = carMap[carPlates[i]];
            emit CarDetails(
                car.carPlate,
                car.state,
                car.deposit,
                car.price,
                car.user
            );
        }
    }

    function isCarAvailable(string memory carPlate) public view carExists(carPlate) returns (bool) {
        Car storage car = carMap[carPlate];
        return car.state == State.Available;
    }

    function rentCar(string memory carPlate) external carExists(carPlate) {
        Car storage car = carMap[carPlate];
        require(car.state == State.Available, "Car is already rented.");
        require(car.deposit + car.price <= token.balanceOf(msg.sender), "You have insufficient CRS balance to rent this car");

        // transfer tokens (price + deposit) from the renter to the contract
        uint totalRental = car.deposit + car.price;

        car.state = State.Unavailable;
        car.user = msg.sender;
        token.transferFrom(msg.sender, wallet, totalRental);

        emit CarRented(carPlate, msg.sender);
    }

    function damageCheck() private view returns (bool) {
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Replaced block.difficulty
            msg.sender
        ))) % 100; // A number between 0-99
        return random < 50; // Set damage probability to 50%
    }

    function returnCar(string memory carPlate) external {
        Car storage car = carMap[carPlate];
        require(car.user == msg.sender, "You are not the renter of this car.");

        bool isDamaged = damageCheck();

        uint refundAmount = car.deposit;
        uint damageFee = 0;

        // if car is damaged, reduce the refunded amount and return isDamaged back to false
        // damage fee is 50% of the car price
        if (isDamaged) {
            damageFee = car.price / 2;
            refundAmount -= damageFee;
            emit CarLog(carPlate, "is damaged");
        }else{
            car.state = State.Available;
        }

        token.transferFrom(wallet, msg.sender, refundAmount);
        car.user = owner;


        emit CarReturned(carPlate, msg.sender, car.state, refundAmount, damageFee);
    }

    function fixCars() external onlyOwner{
        require(carPlates.length > 0, "No cars are available.");
        for (uint256 i = 0; i < carPlates.length; i++) {
            Car storage car = carMap[carPlates[i]];
            if(car.user == owner && car.state == State.Unavailable){
                car.state = State.Available;
                emit CarLog(car.carPlate, "is fixed");
            }
        }
    }
}
