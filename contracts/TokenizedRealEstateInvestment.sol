// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenizedRealEstateInvestment
 * @dev ERC20 token representing fractional ownership in real estate with dividend payouts
 */
contract TokenizedRealEstateInvestment is ERC20, Ownable {
    // Total dividends distributed per token (scaled by magnitude)
    uint256 public totalDividendsPerToken;

    // Magnitude for dividend calculations to maintain precision
    uint256 private constant magnitude = 2**128;

    // Mapping of user addresses to their dividend corrections
    mapping(address => int256) private dividendCorrections;

    // Mapping of user addresses to dividends withdrawn
    mapping(address => uint256) private withdrawnDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(address indexed distributor, uint256 amount);

    // Event emitted when a shareholder withdraws dividends
    event DividendWithdrawn(address indexed shareholder, uint256 amount);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Allows owner to mint new tokens representing new contributions to the asset
     * @param to Address to mint tokens to
     * @param amount Number of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        // Adjust dividend corrections for minting
        dividendCorrections[to] -= int256(totalDividendsPerToken * amount);
    }

    /**
     * @dev Allows owner to burn tokens, e.g. selling asset share back
     * @param from Address to burn tokens from
     * @param amount Number of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyOwner {
        // Adjust dividend corrections for burning
        dividendCorrections[from] += int256(totalDividendsPerToken * amount);
        _burn(from, amount);
    }

    /**
     * @dev Distribute dividends in ETH to token holders proportionally
     */
    function distributeDividends() external payable onlyOwner {
        require(totalSupply() > 0, "No tokens minted");
        require(msg.value > 0, "No dividends sent");

        totalDividendsPerToken += (msg.value * magnitude) / totalSupply();

        emit DividendsDistributed(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw pending dividends for caller
     */
    function withdrawDividends() external {
        uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
        require(_withdrawableDividend > 0, "No dividends to withdraw");

        withdrawnDividends[msg.sender] += _withdrawableDividend;
        payable(msg.sender).transfer(_withdrawableDividend);

        emit DividendWithdrawn(msg.sender, _withdrawableDividend);
    }

    /**
     * @dev Returns the dividend balance that can be withdrawn by an address
     * @param shareholder Address to query
     */
    function withdrawableDividendOf(address shareholder) public view returns (uint256) {
        return accumulativeDividendOf(shareholder) - withdrawnDividends[shareholder];
    }

    /**
     * @dev Returns total dividends allocated to a shareholder
     */
    function accumulativeDividendOf(address shareholder) public view returns (uint256) {
        return uint256(int256(totalDividendsPerToken * balanceOf(shareholder)) + dividendCorrections[shareholder]) / magnitude;
    }

    // Internal override to adjust dividend correction on transfers
    function _transfer(address from, address to, uint256 amount) internal override {
        super._transfer(from, to, amount);

        int256 _magCorrection = int256(totalDividendsPerToken * amount);

        dividendCorrections[from] += _magCorrection;
        dividendCorrections[to] -= _magCorrection;
    }
}
