// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../common/IReferral.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../common/IPointsArgs.sol";

//Integral recommendation system
//Manual upgrade
//Staking system
contract PointsSystem is AccessControl, ReentrancyGuard, Ownable, ERC721Holder {
    bytes32 public constant PLATFORM_ROLE = keccak256("PLATFORM_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    struct User {
        uint256 point;
        //The level of the users
        // uint16 userLevel;
        //The tokenID of the staked NFT
        uint256 stakeNFT;
        //Whether the user mint NFT or not
        bool mint;
        //Direct or indirect rewards, reward DBM
        uint256 pendingReward;
    }

    mapping(address => User) users;

    //The price of the first purchase of an NFT
    uint256 public firstNftPrice;

    using SafeERC20 for IERC20;
    IERC20 public usdt; // usdt

    IERC20 public dbm; // dbm token address

    IReferral public nft;

    IPointsArgs public args;

    event Upgrade(address user, uint16 level, uint8 typ);
    event Stake(address user, uint256 tokenId, uint256 time);
    event Unstake(address user, uint256 tokenId, uint256 time);
    event Increase(uint256 id, uint8 typ, address user, uint256 score);
    event Mint(address user, uint256 tokenId, uint256 time);
    event UsePoint(uint8 typ, address user, uint256 score, uint256 time);
    event Reward(uint8 typ, address user, uint256 amount, uint256 time);
    event PendingReward(
        uint256 id,
        uint8 typ,
        address user,
        uint256 amount,
        uint256 time
    );

    constructor(
        IERC20 usdt_,
        IPointsArgs args_,
        IReferral nft_,
        address platFormAddr_,
        address admin_,
        uint256 firstNftPrice_
    ) {
        usdt = usdt_;
        nft = nft_;
        args = args_;

        //Initialize permissions
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(PLATFORM_ROLE, platFormAddr_);
        _grantRole(ADMIN_ROLE, admin_);

        firstNftPrice = firstNftPrice_;
    }

    function setArgs(IPointsArgs _args) public onlyRole(ADMIN_ROLE) {
        args = _args;
    }

    function setLevel1Price(uint256 _price) public onlyRole(ADMIN_ROLE) {
        firstNftPrice = _price;
    }

    function setDBM(IERC20 _dbm) public onlyRole(ADMIN_ROLE) {
        dbm = _dbm;
    }

    //Increase your points
    function increase(
        uint256 id,
        uint8 typ,
        address user,
        uint256 score
    ) public onlyRole(PLATFORM_ROLE) {
        users[user].point += score;
        emit Increase(id, typ, user, score);
    }

    function increaseBatch(
        uint256[] memory id,
        uint8[] memory typs,
        address[] memory iUsers,
        uint256[] memory scores
    ) public onlyRole(PLATFORM_ROLE) {
        require(typs.length == iUsers.length, "The parameter is incorrect");
        require(iUsers.length == scores.length, "The parameter is incorrect");
        for (uint i = 0; i < iUsers.length; i++) {
            increase(id[i], typs[i], iUsers[i], scores[i]);
        }
    }

    function mintNft() public {
        require(users[_msgSender()].mint == false, "You've mint NFT");
        require(firstNftPrice > 0, "There is no NFT price set");
        require(checkStaked(_msgSender()) == 0, "You already have level");
        //How to buy with USDT to reach level 1 without points
        uint needScoreV1 = args.score(1);

        if (Score(_msgSender()) < needScoreV1) {
            usdt.safeTransferFrom(_msgSender(), address(this), firstNftPrice);
        } else {
            users[_msgSender()].point -= needScoreV1;
            emit UsePoint(0, _msgSender(), needScoreV1, block.timestamp);
        }

        uint256 tokenId = nft.mint(_msgSender());
        users[_msgSender()].mint = true;
        nft.setLevel(tokenId, 1);
        emit Mint(_msgSender(), tokenId, block.timestamp);
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

    //Upgrade the level system
    function upgrade() public {
        //Current user level
        uint256 need = args.score(currentLevel(_msgSender()) + 1);
        require(Score(_msgSender()) > need, "Not enough points");

        //Spend points
        users[_msgSender()].point -= need;
        emit UsePoint(0, _msgSender(), need, block.timestamp);

        //upgrade
        setLevel(_msgSender(), currentLevel(_msgSender()) + 1);

        //Reward DBM
        uint256 dbmNeed = args.reward(currentLevel(_msgSender()));
        _rewardsReferral(0, 1, _msgSender(), dbmNeed);
    }

    function Score(address user) public view returns (uint256) {
        return users[user].point;
    }

    function currentLevel(address user) public view returns (uint16) {
        uint256 tokenId = checkStaked(user);
        require(tokenId > 0, "No staked NFTs");
        return nft.getLevel(tokenId);
    }

    function pendingReward(address user) public view returns (uint256) {
        return users[user].pendingReward;
    }

    function setLevel(address user, uint16 level) internal {
        uint256 tokenId = checkStaked(user);
        if (level > 1) {
            require(tokenId > 0, "No staked NFTs");
        }
        nft.setLevel(tokenId, level);
        //Upgrade NFT levels
        emit Upgrade(_msgSender(), currentLevel(_msgSender()), 1);
    }

    //Referral RewardsReferral
    function rewardsReferral(
        uint256 id,
        uint8 typ,
        address user,
        uint256 score
    ) public onlyRole(PLATFORM_ROLE) {
        _rewardsReferral(id, typ, user, score);
    }

    function _rewardsReferral(
        uint256 id,
        uint8 typ,
        address user,
        uint256 score
    ) internal {
        if (checkStaked(user) > 0) {
            users[user].pendingReward += score;
            emit PendingReward(id, typ, user, score, block.timestamp);
        }
    }

    function rewardsReferralBatch(
        uint256[] memory ids,
        uint8[] memory typ,
        address[] memory user,
        uint256[] memory score
    ) public onlyRole(PLATFORM_ROLE) {
        require(
            typ.length == user.length && user.length == score.length,
            "The parameter is incorrect"
        );
        for (uint i = 0; i < typ.length; i++) {
            rewardsReferral(ids[i], typ[i], user[i], score[i]);
        }
    }

    //Users receive DBM rewards
    function withdrawReward() public {
        require(users[_msgSender()].pendingReward > 0, "There are no rewards");
        require(dbm != IERC20(address(0)), "dbm token has not started yet");
        uint256 amout = users[_msgSender()].pendingReward;
        dbm.safeTransfer(_msgSender(), amout);
        users[_msgSender()].pendingReward = 0;
        emit Reward(0, _msgSender(), amout, block.timestamp);
    }
}
