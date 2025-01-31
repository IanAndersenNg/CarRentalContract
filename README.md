# CarRentalContract

### Overview
This project is the implementation of a smart contract for a car rental company, ABC, that has decided to use blockchain for its car renting business. Using the smart contract, a customer can choose a particular car from the range of cars ABC has, and check the car's availability. If available, the customer uses the smart contract to rent and pay ABC Company. After the rental, the customer uses the smart contract to return the car back to ABC Company, and the company can then release the car for other customers to rent. If a car is returned with damages, the company will ask the customer to pay for the damages. All transactions in the rental car business will be done through an ERC20 token called CARS.

### Execution Steps
1. Using account A, deploy the CARS token and the CarRental contract (henceforth referred to as account B) using the address from the CARS token
2. As account A, approve account B to spend some amount of the CARS token. This amount is for crowdsale purposes
3. Verify that account B has enough allowance for crowdsales
4. Add in some cars using account A
5. As account C, buy some tokens by interacting with the CarRental contract
6. As account C, approve account B to spend some amount of the CARS token. This amount is for car renting purposes, so the amount must be larger than or equal to the total cost of renting the desired car (deposit + price)
7. Attempt to rent a car by referring to its car plate. If the number of tokens is insufficient, an error should be thrown. Otherwise, the car becomes rented
8. As account C, return the rented car by calling the `returnCar` function with the car plate. If the car is damaged, a damage fee (50% of the rental price) will be deducted, and account C must cover this fee. Otherwise, the full deposit is refunded. After returning, the car should no longer be rented