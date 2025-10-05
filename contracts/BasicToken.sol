// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./BaseToken.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal returns(bool){
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        return success;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked { _approve(sender, _msgSender(), currentAllowance - amount); }
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked { _balances[sender] = senderBalance - amount; }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract BasicToken is ERC20, Ownable, BaseToken {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public constant VERSION = 1;
    mapping (address => bool) private _isExcludedFromFees;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public buyFee;
    uint256 public sellFee;
    address public marketingWallet;
    uint256 public swapTokensAtAmount;
    bool private swapping;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndSendMarketing(uint256 tokensSwapped, uint256 ethSend);

    constructor (
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address router_,
        uint256 buyFee_,
        uint256 sellFee_,
        address marketingWallet_,
        address feeReceiver_,
        uint256 serviceFee_
    ) payable ERC20(name_, symbol_) {
        require(marketingWallet_ != address(0), "Marketing wallet cannot be the zero address");
        require(buyFee_ + sellFee_ <= 20, "Total fees must be less than 20%");

        // Only initialize Uniswap if router is not zero address
        if (router_ != address(0)) {
            try IUniswapV2Router02(router_).factory() returns (address factory) {
                if (factory != address(0)) {
                    uniswapV2Router = IUniswapV2Router02(router_);
                    try IUniswapV2Factory(factory).createPair(address(this), IUniswapV2Router02(router_).WETH()) returns (address pair) {
                        uniswapV2Pair = pair;
                        _approve(address(this), address(uniswapV2Router), type(uint256).max);
                    } catch {
                        // Pair creation failed, continue without Uniswap
                        uniswapV2Router = IUniswapV2Router02(address(0));
                        uniswapV2Pair = address(0);
                    }
                }
            } catch {
                // Router doesn't exist, continue without Uniswap
                uniswapV2Router = IUniswapV2Router02(address(0));
                uniswapV2Pair = address(0);
            }
        }

        buyFee = buyFee_;
        sellFee = sellFee_;
        marketingWallet = marketingWallet_;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(DEAD)] = true;
        _isExcludedFromFees[address(this)] = true;

        _mint(owner(), totalSupply_ * (10 ** decimals()));
        swapTokensAtAmount = totalSupply() / 5000;

        emit TokenCreated(owner(), address(this), TokenType.basicToken, 1);
        payable(feeReceiver_).transfer(serviceFee_);
    }

    receive() external payable {}

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // Skip fee logic if no Uniswap pair or no fees
        if (uniswapV2Pair == address(0) || (buyFee == 0 && sellFee == 0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapping && to == uniswapV2Pair && buyFee + sellFee > 0 && !_isExcludedFromFees[from]) {
            swapping = true;
            swapAndSendMarketing(contractTokenBalance);
            swapping = false;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;
        } else if (from == uniswapV2Pair) {
            _totalFees = buyFee;
        } else {
            _totalFees = sellFee;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 100;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    function swapAndSendMarketing(uint256 tokenAmount) private {
        if (address(uniswapV2Router) == address(0)) return; // Skip if no router
        
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        ) {} catch { return; }

        uint256 newBalance = address(this).balance - initialBalance;
        payable(marketingWallet).sendValue(newBalance);
        emit SwapAndSendMarketing(tokenAmount, newBalance);
    }
}