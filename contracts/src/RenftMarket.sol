// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Signature} from "./utils/Signature.sol";
import {IRenftMarket} from "./interface/IRenftMarket.sol";

/**
 * @title RenftMarket
 * @dev NFT租赁市场合约
 *   TODO:
 *      1. 退还NFT：租户在租赁期内，可以随时退还NFT，根据租赁时长计算租金，剩余租金将会退还给出租人
 *      2. 过期订单处理：
 *      3. 领取租金：出租人可以随时领取租金
 */
contract RenftMarket is IRenftMarket, EIP712 {
    using ECDSA for bytes;

    IERC721 public nft;
    mapping(bytes32 => BorrowOrder) public orders; // 已租赁订单
    mapping(bytes32 => bool) public canceledOrders; // 已取消订单
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "RentoutOrder(address maker,address nft_ca,uint256 token_id,uint256 daily_rent,uint256 max_rental_duration,uint256 min_collateral,uint256 list_endtime)"
        );

    constructor() EIP712("RenftMarket", "1") {}

    function borrow(
        RentoutOrder calldata order, 
        bytes calldata makerSignature
    ) external payable {
        bytes32 borrowHash = this.orderHash(order);

        // 检查订单是否已取消
        if (canceledOrders[borrowHash]) {
            revert ErrorOrderCancelled(order);
        }

        // 检查订单是否已经被借出
        if (orders[borrowHash].taker != address(0)) {
            revert ErrorOrderRented(order);
        }

        // 检查订单是否已过期
        if (block.timestamp > order.list_endtime) {
            revert ErrorOrderExpired(order);
        }

        // 检查钱是否足够
        if (msg.value < order.min_collateral) {
            revert ErrorMoneyNotEnough(msg.value, order.min_collateral);
        }

        // 检查签名
        _verifyOrder(order, makerSignature);
        _GenerateOrder(order, borrowHash);
        emit BorrowNFT(msg.sender, order.maker, borrowHash, msg.value);
    }

    function cancelOrder(
        RentoutOrder calldata order,
        bytes calldata makerSignature
    ) external {
        bytes32 borrowHash = this.orderHash(order);

        // 检查订单是否已取消
        if (canceledOrders[borrowHash]) {
            revert ErrorOrderCancelled(order);
        }

        _verifyOrder(order, makerSignature);
        canceledOrders[borrowHash] = true;
        emit OrderCanceled(order.maker, borrowHash);
    }

    function orderHash(
        RentoutOrder calldata order
    ) external pure returns (bytes32) {
        return 
            keccak256(
                abi.encode(
                    _PERMIT_TYPEHASH,
                    order.maker,
                    order.nft_ca,
                    order.token_id,
                    order.daily_rent,
                    order.max_rental_duration,
                    order.min_collateral,
                    order.list_endtime
                )
            );
    }

    function _verifyOrder(
        RentoutOrder calldata order,
        bytes calldata makerSignature
    ) internal view {
        bytes32 hashStruct = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                order.maker,
                order.nft_ca,
                order.token_id,
                order.daily_rent,
                order.max_rental_duration,
                order.min_collateral,
                order.list_endtime
            )
        );
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparatorV4(), hashStruct)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = Signature.toVRS(makerSignature);

        address signer = ECDSA.recover(hash, v, r, s);
        
        // 检查签名者是否是出租人
        if (signer != order.maker || signer == address(0)) {
            revert ErrorWrongSigner(signer, order.maker);
        }
    }

    function _GenerateOrder(
        RentoutOrder calldata order,
        bytes32 borrowHash
    ) internal {
        BorrowOrder memory _borrowOrder = BorrowOrder({
            taker: msg.sender,
            collateral: msg.value,
            start_time: block.timestamp,
            rentinfo: order
        });

        IERC721(order.nft_ca).safeTransferFrom(
            order.maker, 
            msg.sender, 
            order.token_id
        );

        orders[borrowHash] = _borrowOrder;
    }
}
