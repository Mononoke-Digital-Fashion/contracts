// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mononoke is ERC1155, Ownable {
    constructor() ERC1155("") {}

    struct NFT {
        uint price;
        uint priceAfterAllow;
        uint airdropAmount;
        uint userAmount;
        uint currentAirdropAmount;
        uint currentUserAmount;
        uint creationTime;
        uint allowTime;
        bool paused;
        string uri;
    }

    uint startFrom = 101;
    NFT[] NFTs;
    mapping(address => bool)[][] allowed;

    function addNFT(uint price, uint priceAfterAllow, uint airdropAmount, uint userAmount, uint allowTime, string memory nftURI, bool paused) public onlyOwner {
        uint256 idx = NFTs.length;
        NFTs.push();
        NFT storage newNFT = NFTs[idx];
        newNFT.price = price;
        newNFT.priceAfterAllow = priceAfterAllow;
        newNFT.airdropAmount = airdropAmount;
        newNFT.userAmount = userAmount;
        newNFT.creationTime = block.timestamp;
        newNFT.allowTime = allowTime;
        newNFT.uri = nftURI;
        newNFT.paused = paused;
        allowed.push();
        allowed[idx].push();
    }

    modifier NFTexists(uint id) {
        require(((id - startFrom) < NFTs.length) && ((id - startFrom) >= 0), "NFT with specified id does not exist.");
        _;
    }

    function pause(uint id) public onlyOwner NFTexists(id) {
        id -= startFrom;
        NFTs[id].paused = true;
    }

    function unpause(uint id) public onlyOwner NFTexists(id) {
        id -= startFrom;
        NFTs[id].paused = false;
    }

    function setPrice(uint id, uint newPrice) public onlyOwner NFTexists(id) {
        id -= startFrom;
        NFTs[id].price = newPrice;
    }

    function setPriceAfterAllow(uint id, uint newPrice) public onlyOwner NFTexists(id) {
        id -= startFrom;
        NFTs[id].priceAfterAllow = newPrice;
    }

    function setMaxAmount(uint id, uint newAidropAmount, uint newUserAmount) public onlyOwner NFTexists(id) {
        id -= startFrom;
        require((newAidropAmount + newUserAmount) == (NFTs[id].airdropAmount + NFTs[id].userAmount), "Total max amount is fixed.");
        require((newAidropAmount >= NFTs[id].currentAirdropAmount) && (newUserAmount >= NFTs[id].currentUserAmount), "Max amount can't be smaller than current amount.");
        NFTs[id].airdropAmount = newAidropAmount;
        NFTs[id].userAmount = newUserAmount;
    }

    function setAllowTime(uint id, uint allowTime) public onlyOwner NFTexists(id) {
        id -= startFrom;
        NFTs[id].allowTime = allowTime;
    }

    function allowToId(address[] memory accounts, uint id) public onlyOwner NFTexists(id) {
        id -= startFrom;
        for (uint256 account = 0; account < accounts.length; account++) {
            allowed[id][allowed[id].length-1][accounts[account]] = true;
        }
    }

    function disallowToId(address[] memory accounts, uint id) public onlyOwner NFTexists(id) {
        id -= startFrom;
        for (uint256 account = 0; account < accounts.length; account++) {
            allowed[id][allowed[id].length-1][accounts[account]] = false;
        }
    }

    function resetAllowList(uint id) public onlyOwner NFTexists(id) {
        id -= startFrom;
        allowed[id].push();
    }

    function getNFT(uint id) public view NFTexists(id) returns(NFT memory) {
        id -= startFrom;
        return NFTs[id];
    }

    function isAllowed(uint id, address account) public view NFTexists(id) returns(bool) {
        id -= startFrom;
        return allowed[id][allowed[id].length-1][account];
    }

    function airdrop(address[] memory accounts, uint id, uint amount) public onlyOwner NFTexists(id) {
        id -= startFrom;
        require((NFTs[id].currentAirdropAmount + (amount * accounts.length)) <= NFTs[id].airdropAmount, "Not enough NFTs to satisfy the amount.");
        for (uint256 account = 0; account < accounts.length; account++) {
            _mint(accounts[account], id + startFrom, amount, "");
            NFTs[id].currentAirdropAmount += amount;
        }
    }

    function mint(uint256 id, uint256 amount)
        public
        payable 
        NFTexists(id)
    {
        id -= startFrom;
        uint price;
        if (((block.timestamp - NFTs[id].creationTime) >= (NFTs[id].allowTime))) price = NFTs[id].priceAfterAllow;
        else price = NFTs[id].price;
        require((NFTs[id].currentUserAmount + amount) <= NFTs[id].userAmount, "Not enough NFTs to satisfy the amount.");
        require(msg.value >= (price * amount), "Insufficient message value.");
        require((((block.timestamp - NFTs[id].creationTime) >= (NFTs[id].allowTime)) || allowed[id][allowed[id].length-1][msg.sender]) && !NFTs[id].paused, "Not allowed to mint.");
        _mint(msg.sender, id + startFrom, amount, "");
        NFTs[id].currentUserAmount += amount;
    }

    function setURI(uint256 id, string memory newURI) public onlyOwner NFTexists(id) {
        id -= startFrom;
        NFTs[id].uri = newURI;
    }

    function uri(uint256 id) public view override(ERC1155) returns (string memory) {
        id -= startFrom;
        if (((id) < NFTs.length) && ((id) >= 0)) return NFTs[id].uri;
        else return "";
    }

    function withdraw(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }
}
