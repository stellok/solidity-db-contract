// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../common/Referral.sol";

//Integral recommendation system
//Manual upgrade
//Staking system
contract PointsSystem is AccessControl, ReentrancyGuard, Ownable {
    bytes32 public constant PLATFORM = keccak256("PLATFORM");

    struct User {
        uint256 point;
        //The level of the users
        uint16 userLevel;
        //The tokenID of the staked NFT
        uint256 stakeNFT;
        //Whether the user mint NFT or not
        bool mint;
        //Direct or indirect rewards, reward DBM
        uint256 pendingReward;
    }

    struct Settings {
        uint score;
        uint256 reward;
    }

    mapping(address => User) users;
    mapping(uint16 => Settings) tableLevel;

    //The price of the first purchase of an NFT
    uint256 public firstNftPrice;

    using SafeERC20 for IERC20;
    IERC20 public usdt; // usdt

    IERC20 public dbm; // dbm token

    Referral public nft;

    event Upgrade(address user, uint16 level);
    event Stake(address user, uint256 tokenId, uint256 time);
    event Unstake(address user, uint256 tokenId, uint256 time);
    event Increase(uint8 typ, address user, uint256 score);
    event Mint(address user, uint256 tokenId, uint256 time);
    event UsePoint(uint8 typ, address user, uint256 score, uint256 time);
    event Reward(uint8 typ, address user, uint256 amount, uint256 time);

    constructor(
        IERC20 dbm_,
        IERC20 usdt_,
        Referral nft_,
        address platFormAddr_
    ) {
        usdt = usdt_;
        nft = nft_;
        dbm = dbm_;

        //Initialize permissions
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PLATFORM, platFormAddr_);
    }

    //Increase your points
    function increase(
        uint8 typ,
        address user,
        uint256 score
    ) public onlyRole(PLATFORM) {
        users[user].point += score;
        emit Increase(typ, user, score);
    }

    function increaseBatch(
        uint8[] memory typs,
        address[] memory iUsers,
        uint256[] memory scores
    ) public onlyRole(PLATFORM) {
        require(typs.length == iUsers.length, "The parameter is incorrect");
        require(iUsers.length == scores.length, "The parameter is incorrect");
        for (uint i = 0; i < iUsers.length; i++) {
            increase(typs[i], iUsers[i], scores[i]);
        }
    }

    function mintNft() public {
        require(users[_msgSender()].mint == false, "You've mint NFT");
        require(currentLevel(_msgSender()) == 0, "level > 1 Not allowed");
        //How to buy with USDT to reach level 1 without points
        uint needScoreV1 = needScore(1);
        if (Score(_msgSender()) > needScoreV1) {
            upgrade();
        } else {
            usdt.safeTransferFrom(_msgSender(), address(this), firstNftPrice);
            setLevel(_msgSender(), 1);
        }
        nft.mint(_msgSender());
        users[_msgSender()].mint = true;
    }

    //Users can stake NFTs to get invitation rewards
    function unStake() public {
        uint256 tokenId = checkStaked(_msgSender());
        require(tokenId > 0, "You haven't staked yet");
        nft.safeTransferFrom(
            address(this),
            _msgSender(),
            checkStaked(_msgSender())
        );
        users[_msgSender()].stakeNFT = 0;
        emit Unstake(_msgSender(), tokenId, block.timestamp);
    }

    function checkStaked(address user) public view returns (uint256) {
        return users[user].stakeNFT;
    }

    //Stake NFTs
    function stake(uint256 _tokenId) public {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "You do not own this token ID"
        );
        require(checkStaked(_msgSender()) == 0, "You've staked");
        nft.safeTransferFrom(_msgSender(), address(this), _tokenId);
        users[_msgSender()].stakeNFT = _tokenId;
        emit Stake(_msgSender(), _tokenId, block.timestamp);
    }

    function setTaleLevel(
        uint16[] memory _levels,
        uint[] memory _scores,
        uint256[] memory _rewards
    ) public onlyOwner {
        require(
            _levels.length == _scores.length &&
                _scores.length == _rewards.length,
            "The parameter is incorrect"
        );
        for (uint i = 0; i < _levels.length; i++) {
            tableLevel[_levels[i]].score = _scores[i];
            tableLevel[_levels[i]].reward = _rewards[i];
        }
    }

    //Upgrade the level system
    function upgrade() public {
        //Current user level
        uint need = needScore(currentLevel(_msgSender()) + 1);
        require(Score(_msgSender()) > need, "Not enough points");

        //Spend points
        users[_msgSender()].point -= need;
        emit UsePoint(0, _msgSender(), need, block.timestamp);

        //upgrade
        setLevel(_msgSender(), currentLevel(_msgSender()) + 1);

        //Reward DBM
        uint256 dbmNeed = needReward(currentLevel(_msgSender()));
        dbm.safeTransfer(_msgSender(), dbmNeed);
    }

    function needReward(uint16 _level) public view returns (uint256) {
        return tableLevel[_level].reward;
    }

    function needScore(uint16 _level) public view returns (uint) {
        return tableLevel[_level].score;
    }

    function Score(address user) public view returns (uint256) {
        return users[user].point;
    }

    function currentLevel(address user) public view returns (uint16) {
        return users[user].userLevel;
    }

    function setLevel(address user, uint16 level) internal {
        require(checkStaked(user) > 0, "No staked NFTs");
        users[_msgSender()].userLevel = level;
        nft.setLevel(user, level);
        //Upgrade NFT levels
        emit Upgrade(_msgSender(), currentLevel(_msgSender()));
    }

    //Referral RewardsReferral
    function rewardsReferral(
        uint8 typ,
        address user,
        uint256 score
    ) public onlyRole(PLATFORM) {
        users[user].pendingReward += score;
    }

    //Users receive DBM rewards
    function withdrawReward() public {
        require(users[_msgSender()].pendingReward > 0, "There are no rewards");
        dbm.safeTransfer(_msgSender(), users[_msgSender()].pendingReward);
        users[_msgSender()].pendingReward = 0;
    }
}
