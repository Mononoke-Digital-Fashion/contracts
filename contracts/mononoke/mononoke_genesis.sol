// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Mononoke is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("Mononoke", "MNK") {
        _tokenIds._value = 100;
    }

    function safeMint(address to, string[] memory uris) public onlyOwner {
        require(uris.length > 0, "At least one URI should be provided");

        for (uint256 i = 0; i < uris.length; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(to, newItemId);
            _setTokenURI(newItemId, uris[i]);
        }
    }
}
