

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

import "./pegasus.sol";

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract ICO {
    using SafeMath for uint;
    
    Pegasus public token;
    address public owner;
    address public ceoAddress = 0xAF41Ed0573b65C43C78Afdee17BCae7f07e7A4C3;

    uint availableToken;
    uint MinPurchase=10000000;
    uint MaxPurchase=400000000;

    uint timeLimit1 = 1639132200; // unix timestamp in 2021.12.10 10:30 (UTC)
    uint timeLimit2 = 1640428200; // unix timestamp in 2021.12.25 10:30 (UTC)
    uint timeLimit3 = 1641810600; // unix timestamp in 2022.1.10 10:30 (UTC)

    mapping (address => uint256) public buyerList;
    mapping (address => uint256) public leftAmountList;

    AggregatorV3Interface internal pricefeed;
    
    constructor (Pegasus _token){
        token=_token;
        owner=msg.sender;
        // pricefeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        pricefeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
    }

    function buy(uint256 _tokenNum) external payable {
        int256 data = getThePrice();
        uint256 bnbPrice = uint256(data);
        uint256 price = 30000000;
        uint256 total = price.mul(_tokenNum);
        total = total.mul(10**8);
        total = total.div(bnbPrice);
        require(buyerList[msg.sender] == 0, 'User can buy only 1 time');
        require(total >= MinPurchase , 'Please Buy Pegasus more than 0.1BNB');
        require(total <= MaxPurchase , 'Please Buy Pegasus less than 4BNB');
        require(total <= msg.value , 'Please Send More Funds');
        total = total * 10 ** 10;
        payable(ceoAddress).transfer(total);
        buyerList[msg.sender] = _tokenNum.mul(10**18);
        leftAmountList[msg.sender] = 100;
    }

    function claim() external {
      uint256 amount = buyerList[msg.sender];
      require(amount > 0, 'Please buy token and claim');
      if (block.timestamp <= timeLimit1 && leftAmountList[msg.sender] == 100) {
        amount = amount.mul(33).div(100);
        leftAmountList[msg.sender] = 77;
        token.transfer(msg.sender, amount);
      } else if (block.timestamp > timeLimit1 && block.timestamp <= timeLimit2 && leftAmountList[msg.sender] == 77) {
        amount = amount.mul(33).div(100);
        leftAmountList[msg.sender] = 34;
        token.transfer(msg.sender, amount);
      } else if (block.timestamp > timeLimit2 && block.timestamp <= timeLimit3 && leftAmountList[msg.sender] == 34) {
        amount = amount.mul(34).div(100);
        leftAmountList[msg.sender] = 0;
        buyerList[msg.sender] = 0;
        token.transfer(msg.sender, amount);
      } 
    }

    function transferOwnership(address _owner) public{
        require(msg.sender==owner);
        owner=_owner;
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }

    function getThePrice() public view returns (int) {
        (
            uint80 roundId, 
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = pricefeed.latestRoundData();
        return answer;
    }
    
    
}