//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MegaBucks is ERC20 {
    /**
     * @notice max supply = 100.000.000 mBUCKS
     */

    constructor(address _minter) ERC20("MegaBucks Token", "mBUCKS") {
        _mint(_minter, 1e26);
    }
}
