// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";

contract Presale_Swap is AccessControl, Pausable {
    using SafeMath for uint256;
    address _tokenArgh;
    AggregatorV3Interface internal _priceFeed;
    uint256 _tokenPrice = 0;
    mapping(address => bool) public _hasPurchased;
    address[] public _buyers;
    uint256 _maxBNB_User = 3e18;
    uint256 _minBNB_User = 2e17;

    /**
     * Token Price in USD
     * Decimals: 8
     */

    /**
     * Network: BSC Mainnet
     * Aggregator: BNB/USD
     * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
     */

    /**
     * Network: BSC Testnet
     * Aggregator: BNB/USD
     * Address: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
     */
    constructor(address token) {
        _tokenArgh = token;
        _priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdminRole() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Presale Swap: !admin"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyAdminRole {
        require(msg.sender != newOwner, "Presale Swap: !same address");
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function swap() public payable whenNotPaused returns (bool) {
        uint256 bnb_amount = msg.value;
        (, int256 price, , , ) = _priceFeed.latestRoundData();

        uint256 token_amount = (bnb_amount * uint256(price)) / _tokenPrice;

        require(!_hasPurchased[msg.sender], "Presale Swap: Already purchased!");

        require(
            bnb_amount <= _maxBNB_User,
            "Presale Swap: Exceed Max BNB Per User!"
        );

        require(
            bnb_amount >= _minBNB_User,
            "Presale Swap: Smaller than Min BNB!"
        );

        require(
            ERC20(_tokenArgh).balanceOf(address(this)) >= token_amount,
            "Presale Swap: Not enough Argh Token !"
        );
        _hasPurchased[msg.sender] = true;
        _buyers.push(msg.sender);
        bool res = ERC20(_tokenArgh).transfer(msg.sender, token_amount);
        return res;
    }

    function sendToken(address wallet) public onlyAdminRole {
        require(
            ERC20(_tokenArgh).balanceOf(address(this)) > 0,
            "Presale Swap: Token balance is zero !"
        );
        ERC20(_tokenArgh).transfer(
            wallet,
            ERC20(_tokenArgh).balanceOf(address(this))
        );
    }

    function resetRound() public onlyAdminRole {
        for (uint256 i = 0; i < _buyers.length; i++) {
            _hasPurchased[_buyers[i]] = false;
        }
        delete _buyers;
    }

    function sendBNB(address wallet) public onlyAdminRole {
        require(
            address(this).balance > 0,
            "Presale Swap: BNB balance is zero !"
        );
        address payable receiver = payable(wallet);
        receiver.transfer(address(this).balance);
    }

    function setMaxBNB_User(uint256 amount) public onlyAdminRole {
        _maxBNB_User = amount;
    }

    function getMaxBNB_User() public view returns (uint256) {
        return _maxBNB_User;
    }

    function setMinBNB_User(uint256 amount) public onlyAdminRole {
        _minBNB_User = amount;
    }

    function getMinBNB_User() public view returns (uint256) {
        return _minBNB_User;
    }
    function buringToken() pub{
        burn(asdf)
    }
    
    function setTokenPrice(uint256 price) public onlyAdminRole {
        _tokenPrice = price;
    }

    function getTokenPrice() public view returns (uint256) {
        return _tokenPrice;
    }

    function getTokenAmount() public view returns (uint256) {
        uint256 balance = ERC20(_tokenArgh).balanceOf(address(this));
        return balance;
    }

    function getBNBAmount() public view returns (uint256) {
        return address(this).balance;
    }

    function getBNBPrice() public view returns (uint256) {
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        return uint256(price);
    }

    function pause() external onlyAdminRole {
        super._pause();
    }

    function unpause() external onlyAdminRole {
        super._unpause();
    }
}
