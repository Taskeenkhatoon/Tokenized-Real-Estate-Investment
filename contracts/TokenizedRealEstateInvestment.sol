out of 10000 (e.g., 500 = 5%)
    }

    mapping(uint256 => uint256) public tokenPrices;
    mapping(uint256 => uint256) public tokenEvolutionStages;
    mapping(uint256 => mapping(uint256 => string)) public evolutionStageURIs;
    mapping(uint256 => uint256) public lastEvolved;
    mapping(uint256 => Royalty) public royaltyInfo;

    uint256 public evolutionCooldown = 1 days;

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed owner);
    event NFTPurchased(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event NFTEvolved(uint256 indexed tokenId, uint256 newStage);
    event NFTRelisted(uint256 indexed tokenId, uint256 price);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);

    constructor() ERC721("DynamicNFT", "DNFT") {}

    function createAndListNFT(string memory uri, uint256 price, address royaltyReceiver, uint96 royaltyFee) external returns (uint256) {
        require(price > 0, "Price must be > 0");
        require(royaltyFee <= 1000, "Max 10% royalty");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        tokenEvolutionStages[tokenId] = 1;
        evolutionStageURIs[tokenId][1] = uri;
        tokenPrices[tokenId] = price;
        lastEvolved[tokenId] = block.timestamp;

        royaltyInfo[tokenId] = Royalty(royaltyReceiver, royaltyFee);

        emit NFTListed(tokenId, msg.sender, price);
        return tokenId;
    }

    function purchaseNFT(uint256 tokenId) external payable nonReentrant {
        uint256 price = tokenPrices[tokenId];
        require(price > 0, "NFT not for sale");
        require(msg.value >= price, "Insufficient funds");

        address seller = ownerOf(tokenId);

        Royalty memory royalty = royaltyInfo[tokenId];
        uint256 royaltyAmount = (price * royalty.feeNumerator) / 10000;

        delete tokenPrices[tokenId];

        _transfer(seller, msg.sender, tokenId);
        payable(seller).transfer(price - royaltyAmount);

        if (royaltyAmount > 0) {
            payable(royalty.receiver).transfer(royaltyAmount);
        }

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit NFTPurchased(tokenId, seller, msg.sender, price);
    }

    function evolveNFT(uint256 tokenId, string memory newStageURI) external {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(block.timestamp >= lastEvolved[tokenId] + evolutionCooldown, "Cooldown not passed");

        uint256 newStage = tokenEvolutionStages[tokenId] + 1;
        tokenEvolutionStages[tokenId] = newStage;
        evolutionStageURIs[tokenId][newStage] = newStageURI;
        lastEvolved[tokenId] = block.timestamp;

        _setTokenURI(tokenId, newStageURI);
        emit NFTEvolved(tokenId, newStage);
    }

    function updateEvolutionCooldown(uint256 newCooldown) external onlyOwner {
        evolutionCooldown = newCooldown;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        Royalty memory r = royaltyInfo[tokenId];
        uint256 royaltyAmount = (salePrice * r.feeNumerator) / 10000;
        return (r.receiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    You can paste in the rest of your existing functions below here unchanged (getOwnedNFTs, burnNFT, getAllListedNFTs, etc)
}
END
// 
update
// 
