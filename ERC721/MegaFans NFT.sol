// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//https://arcadeape.mypinata.cloud/ipfs/QmbJgMZXqPvvQJMrhQir9VDA8f8F8Hsm13MciJL5t3d4Lx/
//https://arcadeape.mypinata.cloud/ipfs/QmVFqpnEAWyPhjA2UhKE2yR6SNPpaWf13WeZ6stxbkJSpC/

contract TNFT is ERC721, ERC721Enumerable, Ownable {

    using Strings for uint256;
    using SafeMath for uint256;
    
    string _baseTokenURI;
    string public baseExtension = ".json";

    mapping(uint256 => uint) public rarityOfId;
    bool public paused = false;
    uint256 maxSupply = 1000;

    uint256 normalPrice = 2;

    mapping(uint => uint256) public presaleMintLimitPerLevel;
    mapping(uint => uint256) public presaleMintPricePerLevel;
    mapping(uint => uint256) public presaleMintedPerLevel;

    mapping(address => bool) public whitelisted;

    bool public presaleOpen = false;
    bool public normalSaleOpen = false;


    event SetBaseURI(string baseURI);    
    event Withdraw(uint256 amount, address addr);    
        
    constructor(
        string memory _name,
        string memory _symbol) ERC721(_name, _symbol) {

        presaleMintLimitPerLevel[1] = 100;
        presaleMintLimitPerLevel[2] = 10;
        presaleMintLimitPerLevel[3] = 25;
        presaleMintLimitPerLevel[4] = 50;
        presaleMintLimitPerLevel[5] = 1;

        presaleMintPricePerLevel[1] = 1;
        presaleMintPricePerLevel[2] = 4;
        presaleMintPricePerLevel[3] = 10;
        presaleMintPricePerLevel[4] = 20;
        presaleMintPricePerLevel[5] = 40;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

   
    //open presale
    function openPresale() public onlyOwner {
        presaleOpen = true;
    }

    //open normal sale
    function openNormalSale() public onlyOwner {
        presaleOpen = false;
        normalSaleOpen = true;
    }

    // randome uint
    function random() private view returns (uint) {       
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1).balance, totalSupply(), msg.sender)));       
    }

    // random rarity generate function
    function mintNFT(uint256 num) public payable {
        require(normalSaleOpen, "Sale not opened!");
        require(msg.value >= normalPrice.mul(num), "Insufficient Amount of mint!");
        require(totalSupply() + num <= maxSupply, "Max supply reached!");
        uint256 supply = totalSupply();
        for(uint256 i = 0; i < num; i++){
            _safeMint( msg.sender, supply + i );
            uint rnd = random();
            if (rnd % 100 == 0){
                rarityOfId[supply + i] = 5;
                continue;
            }
            if (rnd % 50 == 0){
                rarityOfId[supply + i] = 4;
                continue;
            }
            if (rnd % 25 == 0){
                rarityOfId[supply + i] = 3;
                continue;
            }
            if (rnd % 10 == 0){
                rarityOfId[supply + i] = 2;
                continue;
            }
            rarityOfId[supply + i] = 1;
            continue;
        }        
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function renounceOwnership() public override onlyOwner {
       
    }
    
    function internalMint(address _to, uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
   
        require(supply + _mintAmount <= maxSupply);

        for(uint256 i = 0; i < _mintAmount; i++){
            _safeMint(_to, supply + i);
            uint rnd = random();
            if (rnd % 100 == 0){
                rarityOfId[supply + i] = 5;
                continue;
            }
            if (rnd % 50 == 0){
                rarityOfId[supply + i] = 4;
                continue;
            }
            if (rnd % 25 == 0){
                rarityOfId[supply + i] = 3;
                continue;
            }
            if (rnd % 10 == 0){
                rarityOfId[supply + i] = 2;
                continue;
            }
            rarityOfId[supply + i] = 1;
            continue;
        }        
    }
    

    // presale generate NFT per rarity
    function presaleMint(uint256 num, uint256 level) public payable {
        require(presaleOpen, "Presale not opened!");
       // require(msg.value >= presaleMintPricePerLevel[level].mul(num), "Insufficient Amount of mint!");
        require(totalSupply() + num <= maxSupply, "Max supply reached!");        
        require(presaleMintLimitPerLevel[level] >= presaleMintedPerLevel[level].add(num), "Max whitelist mint for custom level reached!");
        uint256 supply = totalSupply();
        for(uint256 i = 0; i < num; i++){
            _safeMint( msg.sender, supply + i );            
            rarityOfId[supply + i] = level;
            continue;         
        }      
        presaleMintedPerLevel[level] = presaleMintedPerLevel[level].add(num);
    }    

    // list own NFT
    function listMyNFTs(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
    	}
    	else {
    		uint256[] memory tokensId = new uint256[](tokenCount);
            for(uint256 i = 0; i < tokenCount; i++){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
    	}        
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit SetBaseURI(_baseTokenURI);
    }    

    // airdrop NFT by random rarity
    function airdropNFT(address _to, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Max supply reached!");
        uint256 supply = totalSupply();        
        for(uint256 i = 0; i < _amount; i++){
            _safeMint( _to, supply + i );
            uint rnd = random();
            if (rnd % 100 == 0){
                rarityOfId[supply + i] = 5;
                continue;
            }
            if (rnd % 50 == 0){
                rarityOfId[supply + i] = 4;
                continue;
            }
            if (rnd % 25 == 0){
                rarityOfId[supply + i] = 3;
                continue;
            }
            if (rnd % 10 == 0){
                rarityOfId[supply + i] = 2;
                continue;
            }
            rarityOfId[supply + i] = 1;
            continue;
        }        
    }
   // function renounceOwnership() public override onlyOwner {
    //    revert("can't renounceOwnership here"); //not possible with this smart contract
    //}

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
 
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function withdraw() public payable onlyOwner {        
        uint256 amount = address(this).balance;
        require(payable(msg.sender).send(amount));        
        emit Withdraw(amount, msg.sender);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal 
    virtual 
    override(ERC721, ERC721Enumerable) {
    	super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface (bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns(bool) {
    	return super.supportsInterface(interfaceId);
    }
}