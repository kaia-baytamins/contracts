// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract Market is IERC1155Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Listing {
        address seller;        // 판매자 주소
        uint256 itemId;        // 판매 아이템 ID
        uint256 amount;        // 판매 수량
        uint256 price;         // 판매 가격 (단위: wei)
        bool isActive;         // 판매 활성 상태
    }

    // 판매 목록 저장
    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    // ERC1155 토큰 컨트랙트 주소
    IERC1155 public inventoryContract;

    // 이벤트
    event ItemListed(uint256 indexed listingId, address indexed seller, uint256 itemId, uint256 amount, uint256 price);
    event ItemPurchased(uint256 indexed listingId, address indexed buyer, uint256 itemId, uint256 amount, uint256 price);
    event ItemCancelled(uint256 indexed listingId, address indexed seller);

    constructor(address _inventoryContract) {
        inventoryContract = IERC1155(_inventoryContract);
    }

    // ERC1155Receiver 인터페이스 구현
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        // 올바른 magic value 반환
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        // 올바른 magic value 반환
        return this.onERC1155BatchReceived.selector;
    }

    // IERC165 인터페이스 확인
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    // ===================
    // 판매 등록
    // ===================
    function listItem(
        uint256 itemId,
        uint256 amount,
        uint256 price
    ) external {
        require(price > 0, "Price must be greater than 0");
        require(amount > 0, "Amount must be greater than 0");
        require(inventoryContract.balanceOf(msg.sender, itemId) >= amount, "Insufficient balance");

        // 판매 등록
        listingCounter++;
        listings[listingCounter] = Listing({
            seller: msg.sender,    // 판매자 주소를 저장
            itemId: itemId,
            amount: amount,
            price: price,
            isActive: true
        });

        // 아이템 잠금 (판매 컨트랙트로 전송)
        inventoryContract.safeTransferFrom(msg.sender, address(this), itemId, amount, "");

        emit ItemListed(listingCounter, msg.sender, itemId, amount, price);
    }

    // ===================
    // 구매 처리
    // ===================
    function purchaseItem(uint256 listingId) external payable {
        Listing storage listing = listings[listingId];
        require(listing.isActive, "Listing is not active");
        require(msg.value == listing.price * listing.amount, "Incorrect payment amount");

        // 아이템 전송: 판매 컨트랙트 → 구매자
        inventoryContract.safeTransferFrom(address(this), msg.sender, listing.itemId, listing.amount, "");

        // 판매자에게 대금 전달
        payable(listing.seller).transfer(msg.value);

        // 판매 상태 업데이트
        listing.isActive = false;

        emit ItemPurchased(listingId, msg.sender, listing.itemId, listing.amount, listing.price);
    }

    // ===================
    // 판매 취소
    // ===================
    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Only the seller can cancel the listing");
        require(listing.isActive, "Listing is not active");

        // 아이템 반환: 컨트랙트 → 판매자
        inventoryContract.safeTransferFrom(address(this), msg.sender, listing.itemId, listing.amount, "");

        // 판매 상태 업데이트
        listing.isActive = false;

        emit ItemCancelled(listingId, msg.sender);
    }
}
