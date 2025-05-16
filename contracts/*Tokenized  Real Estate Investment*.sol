// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Project is ERC20, Ownable {
    // Property details
    struct Property {
        string propertyId;
        string location;
        uint256 propertyValue;
        uint256 rentalIncome;
        uint256 lastDistributionTimestamp;
        bool isActive;
    }

    // Mapping from property ID to property details
    mapping(string => Property) public properties;
    
    // Array to keep track of property IDs
    string[] public propertyIds;
    
    // Total number of tokens representing the property
    uint256 public constant TOKENS_PER_PROPERTY = 1000;
    
    // Events
    event PropertyTokenized(string propertyId, string location, uint256 propertyValue);
    event RentalIncomeDistributed(string propertyId, uint256 amount);
    event PropertySold(string propertyId, uint256 saleAmount);

    constructor() ERC20("Real Estate Token", "RET") Ownable(msg.sender) {}

    /**
     * @dev Tokenize a new property
     * @param _propertyId Unique identifier for the property
     * @param _location Location of the property
     * @param _propertyValue Value of the property in wei
     */
    function tokenizeProperty(
        string memory _propertyId,
        string memory _location,
        uint256 _propertyValue
    ) external onlyOwner {
        require(bytes(_propertyId).length > 0, "Property ID cannot be empty");
        require(_propertyValue > 0, "Property value must be greater than 0");
        require(!properties[_propertyId].isActive, "Property already tokenized");
        
        // Add property to the mapping
        properties[_propertyId] = Property({
            propertyId: _propertyId,
            location: _location,
            propertyValue: _propertyValue,
            rentalIncome: 0,
            lastDistributionTimestamp: block.timestamp,
            isActive: true
        });
        
        // Add property ID to the array
        propertyIds.push(_propertyId);
        
        // Mint tokens representing the property
        _mint(address(this), TOKENS_PER_PROPERTY);
        
        emit PropertyTokenized(_propertyId, _location, _propertyValue);
    }

    /**
     * @dev Distribute rental income to token holders
     * @param _propertyId ID of the property
     * @param _amount Amount of rental income to distribute
     */
    function distributeRentalIncome(string memory _propertyId, uint256 _amount) external payable onlyOwner {
        require(properties[_propertyId].isActive, "Property not active");
        require(msg.value == _amount, "Sent value must match the amount");
        
        Property storage property = properties[_propertyId];
        property.rentalIncome += _amount;
        property.lastDistributionTimestamp = block.timestamp;
        
        // Logic for distribution would involve calculating each token holder's share
        // For simplicity, we're just updating the property's rental income
        // A complete implementation would distribute ETH to token holders based on their token balance
        
        emit RentalIncomeDistributed(_propertyId, _amount);
    }

    /**
     * @dev Purchase tokens for a property
     * @param _propertyId ID of the property
     * @param _tokenAmount Number of tokens to purchase
     */
    function purchaseTokens(string memory _propertyId, uint256 _tokenAmount) external payable {
        require(properties[_propertyId].isActive, "Property not active");
        require(_tokenAmount > 0, "Token amount must be greater than 0");
        
        Property storage property = properties[_propertyId];
        
        // Calculate token price based on property value
        uint256 tokenPrice = property.propertyValue / TOKENS_PER_PROPERTY;
        uint256 totalPrice = tokenPrice * _tokenAmount;
        
        require(msg.value >= totalPrice, "Insufficient funds sent");
        
        // Transfer tokens from contract to buyer
        _transfer(address(this), msg.sender, _tokenAmount);
        
        // Refund excess payment
        if (msg.value > totalPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "Refund failed");
        }
    }
}
