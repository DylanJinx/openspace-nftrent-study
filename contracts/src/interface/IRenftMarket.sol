// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IRenftMarket {
    // 出租信息
    struct RentoutOrder {
        address maker; // 出租方地址
        address nft_ca; // NFT合约地址
        uint256 token_id; // NFT tokenId
        uint256 daily_rent; // 每日租金
        uint256 max_rental_duration; // 最大租赁时长
        uint256 min_collateral; // 最小抵押
        uint256 list_endtime; // 挂单结束时间
    }

    // 租凭信息
    struct BorrowOrder {
        address taker; // 租户地址
        uint256 collateral; // 抵押
        uint256 start_time; // 租赁开始时间
        RentoutOrder rentinfo; // 租凭订单
    }

    function borrow(
        RentoutOrder calldata order, 
        bytes calldata makerSignature
    ) external payable;

    function cancelOrder(
        RentoutOrder calldata order,
        bytes calldata makerSignature
    ) external;

    function orderHash(
        RentoutOrder calldata order
    ) external view returns (bytes32);

    // 租赁NFT事件
    event BorrowNFT(
        address indexed taker, // 租户
        address indexed maker, // 出租人
        bytes32 orderHash,   // 订单哈希
        uint256 collateral   // 抵押
    );
    // 取消订单事件
    event OrderCanceled(
        address indexed maker, // 出租人
        bytes32 orderHash      // 订单哈希
    );

    error ErrorOrderCancelled(RentoutOrder order); // 订单已取消
    error ErrorWrongSigner(address signer, address maker); // 错误的签名者
    error ErrorOrderRented(RentoutOrder order); // 订单已出租
    error ErrorOrderExpired(RentoutOrder order); // 订单已过期
    error ErrorMoneyNotEnough(uint256 collateral, uint256 daily_rent); // 金额不足
}