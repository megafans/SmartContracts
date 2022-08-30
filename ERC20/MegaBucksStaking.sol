//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MegaBucksStaking is Ownable, ReentrancyGuard {
    /**
     * @notice mBUCKS token which is used to be staked
     */
    IERC20 public immutable mBUCKS;

    /**
     * @notice can pause staking, it can not pause unstaking
     */
    bool public paused;

    /**
     * @notice total amount staked
     */
    uint256 public totalStaked;

    /**
     * @notice a mapping of `stakers` => `block.timestamp` when they staked last time
     */
    mapping(address => uint256) public stakingTimes;

    /**
     * @notice a mapping of `stakers` => `amount`of tokens they staked so far
     */
    mapping(address => uint256) public stakedBalances;

    error AmountZero();
    error NotEnoughBalance();
    error StakingPaused();
    error AddressZero();
    error WithdrawFailed();

    event Staked(address indexed _staker, uint256 _amount, uint256 _stakedTime);
    event Unstaked(address indexed _staker, uint256 _amount, uint256 _unstakedTime);
    event RecoveredERC20(address indexed _token, uint256 _amount);
    event RecoveredNFT(address indexed _nft, address indexed _destination, uint256 _amount);
    event StakingIsPaused(bool _paused);

    /**
     * @notice constructor must pass the mBUCKS address
     */
    constructor(address _mBUCKS) {
        if (_mBUCKS == address(0)) revert AddressZero();
        mBUCKS = IERC20(_mBUCKS);
    }

    /**
     * @notice staking mBUCKS to the contract to receive XP.
     * @param _amount the amount of mBUCKS that you want to stake
     */
    function stake(uint256 _amount) external nonReentrant {
        if (paused) revert StakingPaused();
        if (_amount == 0) revert AmountZero();

        stakingTimes[msg.sender] = block.timestamp;
        totalStaked += _amount;
        stakedBalances[msg.sender] += _amount;

        emit Staked(msg.sender, _amount, block.timestamp);
        mBUCKS.transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice unstaking mBUCKS from the contract
     * @param _amount the amount of mBUCKS that you want to unstake
     */
    function unstake(uint256 _amount) external nonReentrant {
        uint256 balance = stakedBalances[msg.sender];
        if (balance < _amount) revert NotEnoughBalance();

        balance -= _amount;
        if (balance == 0) delete stakingTimes[msg.sender];

        stakedBalances[msg.sender] = balance;
        totalStaked -= _amount;

        emit Unstaked(msg.sender, _amount, block.timestamp);

        mBUCKS.transfer(msg.sender, _amount);
    }

    /**
     * @notice pauses the staking, can be called only by the owner
     * @param _pause true/false
     */
    function pause(bool _pause) external onlyOwner {
        paused = _pause;
        emit StakingIsPaused(_pause);
    }

    /**
     * @notice recovers any ERC20 wrongly sent to the contract, can be called only by the owner
     * @param _token the ERC20 we want to recover
     * @param _receiver the receiver of the tokens
     * @param _amount the amount (in wei) that needs to be recovered
     */
    function recoverERC20(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyOwner {
        if (_receiver == address(0)) revert AddressZero();
        if (_token == address(mBUCKS) && _amount > mBUCKS.balanceOf(address(this)) - totalStaked)
            revert WithdrawFailed();

        emit RecoveredERC20(_token, _amount);

        IERC20(_token).transfer(_receiver, _amount);
    }

    /**
     * @notice Recover NFT sent by mistake to the contract
     * @param _nft the NFT address
     * @param _destination where to send the NFT
     * @param _tokenId the token to want to recover
     */
    function recoverNFT(
        address _nft,
        address _destination,
        uint256 _tokenId
    ) external onlyOwner {
        require(_destination != address(0), "Address(0)");
        IERC721(_nft).safeTransferFrom(address(this), _destination, _tokenId);
        emit RecoveredNFT(_nft, _destination, _tokenId);
    }
}
