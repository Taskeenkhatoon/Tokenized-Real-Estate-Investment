const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying RealEstateToken contract...");
  
  // Get the contract factory
  const RealEstateToken = await ethers.getContractFactory("RealEstateToken");
  
  // Deploy the contract
  const realEstateToken = await RealEstateToken.deploy();
  
  // Wait for deployment to complete
  await realEstateToken.deployed();
  
  console.log("RealEstateToken deployed to:", realEstateToken.address);
  
  // Additional deployment steps could be added here, such as:
  // - Verifying the contract on Etherscan
  // - Setting up initial properties
  // - Transferring ownership if needed
  
  console.log("Deployment completed successfully!");
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Error during deployment:", error);
    process.exit(1);
  });
