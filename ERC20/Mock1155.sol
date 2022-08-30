//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Mock1155 is ERC1155 {
    constructor() ERC1155("") {} //solhint-disable

    function mint(address _to, uint256 _tokenId) external {
        _mint(_to, _tokenId, 1, "");
    }
}
