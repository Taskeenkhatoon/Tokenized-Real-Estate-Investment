Total dividends distributed per token (scaled by magnitude)
    uint256 public totalDividendsPerToken;

    Mapping of user addresses to their dividend corrections
    mapping(address => int256) private dividendCorrections;

    Event emitted when dividends are distributed
    event DividendsDistributed(address indexed distributor, uint256 amount);

    Adjust dividend corrections for minting
        dividendCorrections[to] -= int256(totalDividendsPerToken * amount);
    }

    /**
     * @dev Allows owner to burn tokens, e.g. selling asset share back
     * @param from Address to burn tokens from
     * @param amount Number of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyOwner {
        Internal override to adjust dividend correction on transfers
    function _transfer(address from, address to, uint256 amount) internal override {
        super._transfer(from, to, amount);

        int256 _magCorrection = int256(totalDividendsPerToken * amount);

        dividendCorrections[from] += _magCorrection;
        dividendCorrections[to] -= _magCorrection;
    }
}
// 
End
// 
