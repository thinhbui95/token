// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

pragma solidity ^0.8.0;


contract Token is ERC20, Ownable{
    constructor(string memory _name, string memory _symbol)  payable ERC20(_name, _symbol) {
        _mint(msg.sender, 10**9*10**18);
    }

    uint256 constant txBuyPercent = 2000 ; //20%
    uint256 constant txSellPercent  = 2500; //25%
    uint256 constant ZOOM = 10000;
    //address public constant WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address private feeWallet;
    // address public constant router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
    // address public constant factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); //Mainnet
    address public constant router = address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //Testnet
    address public constant factory = address(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc); //Testnet
    bool public isOpen;
    uint256 public blockListing;
    address public pair;



    function _transfer(address from, address to, uint256 amount) internal virtual override {
        if ((isOpen) && (block.number <= blockListing + 10) && (to == pair)) { //Buy token in PancakeSwap
            uint256 txSell = amount * txSellPercent / ZOOM;
            super._transfer(from, feeWallet,txSell);
            uint256 newAmount = amount - txSell;
            super._transfer(from, to, newAmount);
        } else if ((isOpen) && (block.number <= blockListing + 10)&& (from == pair)) { //Buy token in PancakeSwap
            uint256 txBuy = amount * txBuyPercent / ZOOM;
            super._transfer(from, feeWallet,txBuy);
            uint256 newAmount = amount - txBuy;
            require(newAmount <= totalSupply() * 200 / ZOOM, "Can not swap exceed 2% totalSupply");
            require(balanceOf(to) + newAmount <= totalSupply()* 200 / ZOOM, "BalanceOf does exceed 2% totalSupply");
            super._transfer(from, to, newAmount);
        } else {
            super._transfer(from, to , amount);
        }
    }

    function setFeeWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "invalid");
        feeWallet = _wallet;
    }

    function listing() public payable onlyOwner {
        _approve(address(this), router, balanceOf(address(this)));
        IUniswapV2Router02 routerObj = IUniswapV2Router02(router);
        IUniswapV2Factory factoryObj = IUniswapV2Factory(factory);
        pair = factoryObj.getPair(address(this), routerObj.WETH());
        if (pair == address(0)){
            factoryObj.createPair(address(this), routerObj.WETH());
            routerObj.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
            isOpen = true;
            blockListing = block.number;
            pair = factoryObj.getPair(address(this), routerObj.WETH());
        }

    }

    function getBlockNumber() public view returns(uint256){
        return block.number;
    }

    function withdrawEmergency(address _token) public payable onlyOwner {
        if (_token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender,ERC20(_token).balanceOf(address(this)));
        }
    }

    function depositETH() payable public {}

}
