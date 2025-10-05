// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./BasicToken.sol";
import "./StandartToken.sol";

contract TokenManager is Ownable {

    // Address which gets fee while minting tokens
    address public constant feeReceiver = 0x3214763734b9CD1DB0dDa990A089CABF62D6285B;
    // for test purpose fee is set to 10 wei
    uint256 public constant serviceFee = 10;

    address[] public managedTokens;

    event TokenCreated(address indexed tokenAddress, address indexed creator, string tokenType);

    function createBasicToken(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address router_,
        uint256 buyFee_,
        uint256 sellFee_,
        address marketingWallet_
    ) external payable returns (address) {
        BasicToken newToken = new BasicToken{value: serviceFee}(
            name_,
            symbol_,
            totalSupply_,
            router_,
            buyFee_,
            sellFee_,
            marketingWallet_,
            feeReceiver,
            serviceFee
        );
        managedTokens.push(address(newToken));
        emit TokenCreated(address(newToken), msg.sender, "BasicToken");
        return address(newToken);
    }

    function createStandardToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) external payable returns (address) {
        StandardToken newToken = new StandardToken{value: serviceFee}(
            name_,
            symbol_,
            decimals_,
            totalSupply_,
            feeReceiver,
            serviceFee
        );
        managedTokens.push(address(newToken));
        emit TokenCreated(address(newToken), msg.sender, "StandardToken");
        return address(newToken);
    }

    function getManagedTokens() external view returns (address[] memory) {
        return managedTokens;
    }

    function transferTokens(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner returns (bool) {
        IERC20(token).transfer(recipient, amount);
        return true;
    }

    function approveTokens(
        address token,
        address spender,
        uint256 amount
    ) external onlyOwner returns (bool) {
        IERC20(token).approve(spender, amount);
        return true;
    }

    function transferFromTokens(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) external onlyOwner returns (bool) {
        IERC20(token).transferFrom(sender, recipient, amount);
        return true;
    }
}
