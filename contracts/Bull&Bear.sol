// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Dev imports
import "hardhat/console.sol";


contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, VRFConsumerBaseV2, Ownable  {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Add VRF components
    // 0. COORDINATOR def.
    VRFCoordinatorV2Interface COORDINATOR;
    // 1. subscription ID for vrf dashboard
    uint64 s_subscriptionId;
    // 2. goerli coordinator address
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    // 3. gas lane?
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    // 4. call back gas limit(maximum) each word cost about 20,000gas. now we need just 2 digits
    uint32 callbackGasLimit = 300000;
    // 5. request confirmation factor: default 3
    uint16 requestConfirmations = 3;
    // 6. count of retrieve random values
    uint32 numWords = 10;

    // storage of this contract
    uint256[] public s_randomNumbers;
    uint256 public s_requestId;

    address s_owner;
    uint256 maxId = 10;

    // IPFS URIs for the dynamic nft graphics/metadata.
    // NOTE: These connect to my IPFS Companion node.
    // You should upload the contents of the /ipfs folder to your own node for development.
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) ERC721("Bull&Bear", "BBTK") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    // limit onlyOwner to mint new tokens
    function safeMint(address to) public onlyOwner {
        // Current counter value will be the minted token's token ID.
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxId, "Total supply is 10!");

        // Increment it so next time it's correct when we call .current()
        _tokenIdCounter.increment();

        // Mint the token
        _safeMint(to, tokenId);

        // Default to a bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);

        console.log("DONE!!! minted token ", tokenId, " and assigned token url: ", defaultUri);
    }

    function requestRandomWords() external onlyOwner {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomNumbers = randomWords;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function updateAllTokenUris() external onlyOwner {
        require(_tokenIdCounter.current() !=0,"please mint some token");
        require(s_randomNumbers.length != 0,"please request and fulfill RandomWords");
        for (uint i = 0; i < _tokenIdCounter.current(); i++) {
            _setTokenURI(i, bearUrisIpfs[s_randomNumbers[i] % 3]);
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
