// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlanetNFT is ERC721, Ownable {
    address public allowedContract; // 특정 컨트랙트 주소

    uint256 private _tokenIdCounter;

    constructor(string memory name, string memory symbol, address _allowedContract) ERC721(name, symbol) Ownable(msg.sender) {
        allowedContract = _allowedContract;
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == allowedContract, "Not authorized");
        _;
    }

    // 민트 함수
    function mint(address to) external onlyAuthorized {
        uint256 tokenId = _tokenIdCounter + 1;
        _tokenIdCounter = tokenId;

        _mint(to, tokenId);
    }

    // 특정 컨트랙트 변경 (owner만 호출 가능)
    function setAllowedContract(address _allowedContract) external onlyOwner {
        allowedContract = _allowedContract;
    }
}
