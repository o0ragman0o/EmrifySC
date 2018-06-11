pragma solidity 0.4.23;

import "./library.sol";
import "./ERC20.sol";

/*
This Contract deals with the HODL strategy of HIT ICO.
We are four different HODL periods, 3months, 6 months, 
9tmonths and 12 months. 
Here the HODL objects will be created by Token distribution
contract and Invalidate will be done by HIT erc20 contract.
 */
contract Hodler is Ownable {
    using SafeMath for uint256;
    using SafeMath40 for uint40;
    // HODLER reward tracker
    // stake amount per address
    struct HODL {
        uint256 stake;
        // moving ANY funds invalidates hodling of the address
        bool isValid;
        bool claimed3M;
        bool claimed6M;
        bool claimed9M;
        bool claimed12M;
    }

    mapping (address => HODL) public hodlerStakes;

    // total current staking value and hodler addresses
    uint256 public hodlerTotalValue;
    uint256 public hodlerTotalCount;

    // store dates and total stake values for 3 - 6 - 9 - 12 months after normal sale
    uint256 public hodlerTotalValue3M;
    uint256 public hodlerTotalValue6M;
    uint256 public hodlerTotalValue9M;
    uint256 public hodlerTotalValue12M;
    uint40 public hodlerTimeStart;
    uint40 public hodlerTime3M;
    uint40 public hodlerTime6M;
    uint40 public hodlerTime9M;
    uint40 public hodlerTime12M;
    
    // reward HIT token amount
    uint256 public TOKEN_HODL_3M;
    uint256 public TOKEN_HODL_6M;
    uint256 public TOKEN_HODL_9M;
    uint256 public TOKEN_HODL_12M;
    // total amount of tokens claimed so far
    uint256 public claimedTokens;
    
    address tokenDistributionContract;
    address HITTokenContract;

    
    event LogHodlSetStake(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlClaimed(address indexed _setter, address indexed _beneficiary, uint256 _value);
    event LogHodlStartSet(address indexed _setter, uint256 _time);

    ERC20 public tokenContract;
    
    // Only before hodl is started
    modifier beforeHodlStart() {
        if (hodlerTimeStart == 0 || now <= hodlerTimeStart)
            _;
    }
    
    
    // To make sure that only sale distribution contract or admin can create tokenhodler struct for a user.
    modifier onlyAccessContract() {
        require(msg.sender==tokenDistributionContract);
        _;
    }
    
    modifier onlyTokenContract() {
        require(msg.sender==HITTokenContract);
        _;
    }

    // It should be created by a token distribution contract
    constructor(uint256 _stake3m, uint256 _stake6m, uint256 _stake9m,uint256 _stake12m) public {
        TOKEN_HODL_3M = _stake3m;
        TOKEN_HODL_6M = _stake6m;
        TOKEN_HODL_9M = _stake9m;
        TOKEN_HODL_12M = _stake12m;
        
       
    }
    
    /*
    This method will be used , to set the addresses for the deployed token and sale distribution contracts.
    We are following this approach insted of passing in constructor because, we need to deploy the hodler fisrt before
    deploying the HIT ERC20 as it requires hodler.
    */
    function setContractAddresses(address _tokenContractAddress,address _tokenDistributionAddress) public onlyOwner returns (bool) {
        require(tokenContract==address(0));
        tokenContract = ERC20(_tokenContractAddress);
        HITTokenContract = _tokenContractAddress;
        tokenDistributionContract = _tokenDistributionAddress;
        return true;
    }

   // This method can only be called by the sale distribution method 
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyAccessContract beforeHodlStart returns (bool) {
        // real change and valid _beneficiary is needed
        if (_stake == 0 || _beneficiary == address(0))
            return false;
        
        // add stake and maintain count
        if (hodlerStakes[_beneficiary].stake == 0)
            hodlerTotalCount = hodlerTotalCount.add(1);

        hodlerStakes[_beneficiary].stake = hodlerStakes[_beneficiary].stake.add(_stake);
        hodlerTotalValue = hodlerTotalValue.add(_stake);
        hodlerStakes[_beneficiary].isValid = true;

        emit LogHodlSetStake(msg.sender, _beneficiary, hodlerStakes[_beneficiary].stake);
        return true;
    }
   
    // The time when hodler reward starts counting
    function setHodlerTime(uint40 _time) public onlyOwner beforeHodlStart returns (bool) {
        require(_time >= now);
        hodlerTimeStart = _time;
        hodlerTime3M = _time.add(90 days);
        hodlerTime6M = _time.add(180 days);
        hodlerTime9M = _time.add(270 days);
        hodlerTime12M = _time.add(360 days);
        emit LogHodlStartSet(msg.sender, _time);
        return true;
    }

    /* 
    This method can only be called by HIT token contract.
    This will return true: when we successfully invalidate a stake
    false: When we try to invalidate the stake of either already
    invalidated or not participated stake holder in Pre-ico
    */ 
    function invalidate(address _account) public onlyTokenContract returns (bool) {
        if (hodlerStakes[_account].stake > 0 && hodlerStakes[_account].isValid) {
            hodlerStakes[_account].isValid = false;
            hodlerTotalValue = hodlerTotalValue.sub(hodlerStakes[_account].stake);
            hodlerTotalCount = hodlerTotalCount.sub(1);
            delete hodlerStakes[_account];
            return true;
        }
        return false;
    }

    // We are checking whether an address have participated in pre-ico.	
    function checkStakeValidation(address _account) view public returns (bool) {
        if (hodlerStakes[_account].stake > 0 && hodlerStakes[_account].isValid) {
            return true;
        }
        return false;
    }

    // Claiming HODL reward for msg.sender
    function claimHodlReward() public returns (bool) {
        require( claimHodlRewardFor(msg.sender) ) ;
        return true;
    }

    // Claiming HODL reward for an address
    function claimHodlRewardFor(address _beneficiary) public returns (bool) {
        // only when the address has a valid stake
        require(hodlerStakes[_beneficiary].stake > 0 && hodlerStakes[_beneficiary].isValid);
        uint256 _stake = 0;
        
        // claim hodl if not claimed
        if (!hodlerStakes[_beneficiary].claimed3M && now >= hodlerTime3M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
            hodlerStakes[_beneficiary].claimed3M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed6M && now >= hodlerTime6M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_6M).div(hodlerTotalValue));
            hodlerStakes[_beneficiary].claimed6M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed9M && now >= hodlerTime9M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_9M).div(hodlerTotalValue));
            hodlerStakes[_beneficiary].claimed9M = true;
        }
        if (!hodlerStakes[_beneficiary].claimed12M && now >= hodlerTime12M) {
            _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_12M).div(hodlerTotalValue));
            hodlerStakes[_beneficiary].claimed12M = true;
        }

        if (_stake > 0) {
            // increasing claimed tokens
            claimedTokens = claimedTokens.add(_stake);

            // transferring tokens
            require(tokenContract.transfer(_beneficiary, _stake));

            // log
            emit LogHodlClaimed(msg.sender, _beneficiary, _stake);
            
            return true;
        }
        
        return false;
    }
    
    /*
    This method is to complete HODL period. Any leftover tokens will 
    return to first admin and then ultimately added to the growth pool.
    */
    function finalizeHodler() public onlyOwner returns (bool) {
        require(now>=hodlerTime12M);
        uint256 amount = tokenContract.balanceOf(this);
        require(amount > 0);
        require(tokenContract.transfer(owner,amount));
        return true;
    }
    
    

    /*
    `claimHodlRewardFor()` for multiple addresses
    Anyone can call this function and distribute hodl rewards
    _beneficiaries Array of addresses for which we want to claim hodl rewards
    */
    function claimHodlRewardsForMultipleAddresses(address[] _beneficiaries) external returns (bool) {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
	    HODL memory hodler = hodlerStakes[_beneficiaries[i]]; 
            if((
                !hodler.claimed3M || !hodler.claimed6M ||
                !hodler.claimed9M || !hodler.claimed12M) &&
                hodler.stake > 0 && hodler.isValid) {
                    require(claimHodlRewardFor(_beneficiaries[i]));
            }
        }
        return true;
    }
}

