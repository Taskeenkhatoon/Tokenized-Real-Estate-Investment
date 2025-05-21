// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Project is ERC20, Ownable {
    struct Property {
        string propertyId;
        string location;
        uint256 propertyValue;
        uint256 rentalIncome;
        uint256 lastDistributionTimestamp;
        bool isActive;
    }

    mapping(string => Property) public properties;
    string[] public propertyIds;
    uint256 public constant TOKENS_PER_PROPERTY = 1000;

    event PropertyTokenized(string propertyId, string location, uint256 propertyValue);
    event RentalIncomeDistributed(string propertyId, uint256 amount);
    event PropertySold(string propertyId, uint256 saleAmount);
    event TokensBurned(string propertyId, uint256 amount);
    event FundsWithdrawn(address owner, uint256 amount);

    constructor() ERC20("Real Estate Token", "RET") Ownable(msg.sender) {}

    function tokenizeProperty(
        string memory _propertyId,
        string memory _location,
        uint256 _propertyValue
    ) external onlyOwner {
        require(bytes(_propertyId).length > 0, "Property ID cannot be empty");
        require(_propertyValue > 0, "Property value must be greater than 0");
        require(!properties[_propertyId].isActive, "Property already tokenized");

        properties[_propertyId] = Property({
            propertyId: _propertyId,
            location: _location,
            propertyValue: _propertyValue,
            rentalIncome: 0,
            lastDistributionTimestamp: block.timestamp,
            isActive: true
        });

        propertyIds.push(_propertyId);
        _mint(address(this), TOKENS_PER_PROPERTY);

        emit PropertyTokenized(_propertyId, _location, _propertyValue);
    }

    function distributeRentalIncome(string memory _propertyId, uint256 _amount) external payable onlyOwner {
        require(properties[_propertyId].isActive, "Property not active");
        require(msg.value == _amount, "Sent value must match the amount");

        Property storage property = properties[_propertyId];
        property.rentalIncome += _amount;
        property.lastDistributionTimestamp = block.timestamp;

        emit RentalIncomeDistributed(_propertyId, _amount);
    }

    function purchaseTokens(string memory _propertyId, uint256 _tokenAmount) external payable {
        require(properties[_propertyId].isActive, "Property not active");
        require(_tokenAmount > 0, "Token amount must be greater than 0");

        Property storage property = properties[_propertyId];
        uint256 tokenPrice = property.propertyValue / TOKENS_PER_PROPERTY;
        uint256 totalPrice = tokenPrice * _tokenAmount;

        require(msg.value >= totalPrice, "Insufficient funds sent");

        _transfer(address(this), msg.sender, _tokenAmount);

        if (msg.value > totalPrice) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @dev Sell and remove a tokenized property
     * Burns all its tokens and disables it
     */
    function sellProperty(string memory _propertyId, uint256 saleAmount) external onlyOwner {
        require(properties[_propertyId].isActive, "Property not active");

        properties[_propertyId].isActive = false;

        // Burn tokens held by the contract for that property
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            _burn(address(this), contractBalance);
            emit TokensBurned(_propertyId, contractBalance);
        }

        emit PropertySold(_propertyId, saleAmount);
    }

    /**
     * @dev Allow owner to withdraw ETH from contract
     */
    function withdrawFunds(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Not enough balance");
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(owner(), _amount);
    }

    /**
     * @dev Get token price for a property
     */
    function getTokenPrice(string memory _propertyId) external view returns (uint256) {
        require(properties[_propertyId].isActive, "Property not active");
        return properties[_propertyId].propertyValue / TOKENS_PER_PROPERTY;
    }

    /**
     * @dev Get all property IDs
     */
    function getAllPropertyIds() external view returns (string[] memory) {
        return propertyIds;
    }

    // Fallback and receive
    receive() external payable {}
    fallback() external payable {}
}
