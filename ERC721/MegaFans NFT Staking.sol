// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract StakingSystem is Ownable, ERC721Holder {
    IRewardToken public rewardsToken;
    IERC721 public nft;

    uint256 public stakedTotal;
    uint256 constant token = 10e18;
    
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingCoolDown;
    }

    constructor(IERC721 _nft) {
        nft = _nft;
    }

    /// @notice mapping of a staker to its wallet
    mapping(address => Staker) private stakers;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    /// @notice event emitted when a user has staked a nft
    event Staked(address owner, uint256 amount);

    /// @notice event emitted when the game creator unstake
    event Unstaked(address owner, uint256 amount);

    /// @notice event emitted when the Game creator send NFT to winner
    event UnstakedToAddress(address owner, address to, uint256 amount);

    // // Define modifier for set the role
    // modifier serverManager {
    //     require(msg.sender == gameManager);
    //     _;
    // }

    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(
            nft.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );
        Staker storage staker = stakers[_user];

        staker.tokenIds.push(_tokenId);
        // staker.tokenStakingCoolDown[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = _user;
        nft.approve(address(this), _tokenId);
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstake(uint256 _tokenId) public {
        _unstake(msg.sender, _tokenId);
    }

    function unstaketoAddress(uint256 _tokenId, address _to)  public onlyOwner  {
        _unstaketoAddress(msg.sender, _to, _tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds)  public onlyOwner  {
        // claimReward(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }


    function _unstake(address _user, uint256 _tokenId) internal {
       
        Staker storage staker = stakers[_user];

        // uint256 lastIndex = staker.tokenIds.length - 1;
        // uint256 lastIndexKey = staker.tokenIds[lastIndex];
        
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
        }
        // staker.tokenStakingCoolDown[_tokenId] = 0;
        delete tokenOwner[_tokenId];

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }

    
    function _unstaketoAddress(address _user, address _to, uint256 _tokenId) internal {
        
        Staker storage staker = stakers[_user];

        // uint256 lastIndex = staker.tokenIds.length - 1;
        // uint256 lastIndexKey = staker.tokenIds[lastIndex];
        
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
        }
        // staker.tokenStakingCoolDown[_tokenId] = 0;
        delete tokenOwner[_tokenId];

        nft.safeTransferFrom(address(this), _to, _tokenId);

        emit UnstakedToAddress(_user, _to, _tokenId);
        stakedTotal--;
    }
}