// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract DutchAuction {
    uint private constant DURATION = 7 days;

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAt;
    uint public immutable expiresAt;
    uint public immutable discountRate;

    constructor(
        uint _startingPrice,
        uint _discountRate,
        address _nft,
        uint _nftId
    ) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
        discountRate = _discountRate;

        require(
            _startingPrice >= _discountRate * DURATION,
            "starting price < min"
        );

        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view returns (uint) {
        // Code here        
        if(block.timestamp - startAt >= DURATION){
            return 0;
        }
        uint currentPrice = startingPrice - discountRate * (block.timestamp - startAt);
        return currentPrice;
    }

    function buy() external payable {
        // Code here
        require(block.timestamp <= expiresAt, "auction expired");
        uint currentPrice = getPrice();
        require(msg.value >= currentPrice, "bid price too low" );

        // transfer nft to buyer
        nft.transferFrom(seller, msg.sender, nftId);

        // refund excess to buyer
        uint balance = msg.value-currentPrice;
        if(balance > 0){
            (bool success, ) = msg.sender.call{value: balance}("");
            require(success, "excess balance transfer failed");
        }

        // send balance funds to seller
        // and self destruct contract
        selfdestruct(seller);        


    }
}
