//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Mock721 is ERC721 {
    constructor() ERC721("MockERC20", "Mock") {} //solhint-disable

    function mint(address _to, uint256 _tokenId) external {
        _mint(_to, _tokenId);
    }
}
