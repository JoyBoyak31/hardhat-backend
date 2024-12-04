// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Token.sol";
import "hardhat/console.sol";

contract TokenFactory {

    struct memeToken {
        string name;
        string symbol;
        string description;
        string tokenImageURL;
        uint fundingRaised;
        address tokenAddress;
        address creatorAddress;
    }

address[] public memeTokenAddresses;

uint constant DECIMALS = 10 ** 18;
uint constant MAX_SUPPLY = 1000000 * DECIMALS;
uint constant INIT_SUPPLY = 20 * MAX_SUPPLY / 100;

uint constant MEMETOKEN_CREATION_FEE = 0.0001 ether;

uint constant MEMECOIN_FUNDING_GOAL = 24 ether;

    uint256 public constant INITIAL_PRICE = 30000000000000;  // Initial price in wei (P0), 3.00 * 10^13
    uint256 public constant K = 8 * 10**15;  // Growth rate (k), scaled to avoid precision loss (0.01 * 10^18)

mapping(address => memeToken) addressToMemeTokenMapping;

    function createMemeToken(string memory name, string memory symbol, string memory description, string memory imageURL)
    public payable returns(address) {

        require(msg.value >= MEMETOKEN_CREATION_FEE, "Invalid token creation fee");
        Token memeTokenCt = new Token(name, symbol, INIT_SUPPLY);
        address memeTokenAdress = address(memeTokenCt);
        memeTokenAddresses.push(memeTokenAdress); 
        memeToken memory newlyCreatedToken = memeToken(name, symbol, description, imageURL, 0, memeTokenAdress, msg.sender);
        addressToMemeTokenMapping[memeTokenAdress] = newlyCreatedToken;
        console.log("Memecoin successfully deployed", memeTokenAdress);
        return memeTokenAdress;

    }

    // Function to calculate the cost in wei for purchasing `tokensToBuy` starting from `currentSupply`
    function calculateCost(uint256 currentSupply, uint256 tokensToBuy) public pure returns (uint256) {
        
            // Calculate the exponent parts scaled to avoid precision loss
        uint256 exponent1 = (K * (currentSupply + tokensToBuy)) / 10**18;
        uint256 exponent2 = (K * currentSupply) / 10**18;

        // Calculate e^(kx) using the exp function
        uint256 exp1 = exp(exponent1);
        uint256 exp2 = exp(exponent2);

        // Cost formula: (P0 / k) * (e^(k * (currentSupply + tokensToBuy)) - e^(k * currentSupply))
        // We use (P0 * 10^18) / k to keep the division safe from zero
        uint256 cost = (INITIAL_PRICE * 10**18 * (exp1 - exp2)) / K;  // Adjust for k scaling without dividing by zero
        return cost;
    }

    // Improved helper function to calculate e^x for larger x using a Taylor series approximation
    function exp(uint256 x) internal pure returns (uint256) {
        uint256 sum = 10**18;  // Start with 1 * 10^18 for precision
        uint256 term = 10**18;  // Initial term = 1 * 10^18
        uint256 xPower = x;  // Initial power of x
        
        for (uint256 i = 1; i <= 20; i++) {  // Increase iterations for better accuracy
            term = (term * xPower) / (i * 10**18);  // x^i / i!
            sum += term;

            // Prevent overflow and unnecessary calculations
            if (term < 1) break;
        }

        return sum;
    }

    function buyMemeToken(address memeTokenAddress, uint purchaseQty) public payable returns(uint){
        require(addressToMemeTokenMapping[memeTokenAddress].tokenAddress!=address(0), "Token is not listed in the platform");

        memeToken storage listedToken = addressToMemeTokenMapping[memeTokenAddress];

        require(addressToMemeTokenMapping[memeTokenAddress].fundingRaised <= MEMECOIN_FUNDING_GOAL, "Funding has already been raised");

        Token tokenCt = Token(memeTokenAddress);

        uint currentSupply = tokenCt.totalSupply();
        uint availableSupply = MAX_SUPPLY - currentSupply;

        uint availableSupplyScaled = availableSupply / DECIMALS; 
        uint purchaseQtyScaled = purchaseQty * DECIMALS;


        require(purchaseQty <= availableSupplyScaled, "Not enough supply");
        
        // calculate the cost for purchasing purchaseQtyScaled tokens
        uint currentSupplyScaled = (currentSupply - INIT_SUPPLY) / DECIMALS;
        uint requiredEth = calculateCost(currentSupplyScaled, purchaseQty);

        console.log("Required eth for purcghase is ", requiredEth);

        return requiredEth;
    }
}