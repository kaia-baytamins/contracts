// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IERC721Mintable {
    function mint(address to) external;
}

contract Inventory is ERC1155, Ownable {
    
    event ItemUsed(address indexed user, uint256 itemId, uint256 amount);

    // Admin 주소 배열 및 관리자 (백엔드 지갑, 운영자 지갑 등등)
    address[] public admins;
    //ERC721 컨트랙트 주소 매핑 (행성번호 -> ERC721 컨트랙트 주소)
    mapping(uint256 => address) public nftContracts; 

    constructor() ERC1155("https://yourgame.com/api/metadata/{id}.json") Ownable(msg.sender) {
        // 컨트랙트 배포자를 Admin으로 자동 등록
        admins.push(msg.sender);
    }

    // ===================
    // Modifier: Admin만 접근 가능
    // ===================
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not an admin");
        _;
    }

    // ===================
    // Admin 관리 함수
    // ===================
    function addAdmin(address admin) external onlyOwner {
        require(!isAdmin(admin), "Already an admin");
        admins.push(admin);
    }

    function removeAdmin(address admin) external onlyOwner {
        require(isAdmin(admin), "Not an admin");
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == admin) {
                admins[i] = admins[admins.length - 1]; // 마지막 주소로 대체
                admins.pop(); // 배열 크기 감소
                break;
            }
        }
    }

    function isAdmin(address admin) public view returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == admin) {
                return true;
            }
        }
        return false;
    }

    // ===================
    // NFT 주소 셋팅
    // ===================
    function setNFTContract(uint256 itemId, address nftContract) external onlyOwner {
        nftContracts[itemId] = nftContract;
    }


    // ===================
    // 아이템 민팅
    // ===================
    function mintItems(address to, uint256[] memory itemIds, uint256[] memory amounts) 
        external onlyAdmin {
        _mintBatch(to, itemIds, amounts, "");
    }
    
    function mintItem(address to, uint256 itemId, uint256 amount) 
        external onlyAdmin {
        _mint(to, itemId, amount, "");
    }
    
    // ===================
    // 아이템 사용/소각
    // ===================
    function useItems(uint256[] memory itemIds, uint256[] memory amounts, uint256 nftNumber) 
        external {
            for (uint256 i = 0; i < itemIds.length; i++) {
                require(balanceOf(msg.sender, itemIds[i]) >= amounts[i], "Insufficient balance");
            }
            
            //소각
            _burnBatch(msg.sender, itemIds, amounts);
            
            for (uint256 i = 0; i < itemIds.length; i++) {
                emit ItemUsed(msg.sender, itemIds[i], amounts[i]);
            }

            //탐험 NFT민팅
            IERC721Mintable(nftContracts[nftNumber]).mint(msg.sender);
        }


    function useItem(uint256 itemId, uint256 amount, uint256 nftNumber) 
            external {
            require(balanceOf(msg.sender, itemId) >= amount, "Insufficient balance");
            
            _burn(msg.sender, itemId, amount);
            emit ItemUsed(msg.sender, itemId, amount);

            // ERC721 민팅 호출
            IERC721Mintable(nftContracts[nftNumber]).mint(msg.sender);
        }


    
    // ===================
    // 조회 함수들
    // ===================
    function getUserItems(address user, uint256[] memory itemIds) 
        external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](itemIds.length);
        for (uint256 i = 0; i < itemIds.length; i++) {
            balances[i] = balanceOf(user, itemIds[i]);
        }
        return balances;
    }
}
