// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleToken is ERC20 {
    constructor() ERC20("FLX", "FLX") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    fallback() external payable {}

    receive() external payable {}
}
