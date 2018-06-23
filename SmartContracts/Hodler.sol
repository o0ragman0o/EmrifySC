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
        //bool isValid;
        uint40 lastClaimed;
        // bool claimed3M;
        // bool claimed6M;
        // bool claimed9M;
        // bool claimed12M;
    }

    mapping (address => HODL) public hodlerStakes;

    // total current staking value and hodler addresses
    uint256 public hodlerTotalValue;
    uint256 public hodlerTotalCount;

    // store dates and total stake values for 3 - 6 - 9 - 12 months after normal sale
    // uint256 public hodlerTotalValue3M;
    // uint256 public hodlerTotalValue6M;
    // uint256 public hodlerTotalValue9M;
    // uint256 public hodlerTotalValue12M;
    uint40 public hodlerTimeStart;
 
    
    // reward HIT token amount
    uint256 public TOKEN_HODL_3M;
    uint256 public TOKEN_HODL_6M;
    uint256 public TOKEN_HODL_9M;
    uint256 public TOKEN_HODL_12M;
    // total amount of tokens claimed so far
    uint256 public claimedTokens;
    
    address HITTokenContract;

    
    event LogHodlSetStake(address indexed _beneficiary, uint256 _value);
    event LogHodlClaimed(address indexed _beneficiary, uint256 _value);

    ERC20 public tokenContract;
    
    // Only before hodl is started
    modifier beforeHodlStart() {
        if (hodlerTimeStart == 0 || now <= hodlerTimeStart)
            _;
    }

    // It should be created by a token distribution contract
    //Because we cannot multiply rational with integer we are using 75 instead of 7.5 and dividing with 1000 instaed of 100
    constructor(uint256 _stake) public {
        TOKEN_HODL_3M = (_stake*75)/1000;
        TOKEN_HODL_6M = (_stake*15)/100;
        TOKEN_HODL_9M = (_stake*30)/100;
        TOKEN_HODL_12M = (_stake*475)/1000;
        HITTokenContract = ERC20(msg.sender);
    }
    
    // /*
    // This method will be used , to set the addresses for the deployed token and sale distribution contracts.
    // We are following this approach insted of passing in constructor because, we need to deploy the hodler fisrt before
    // deploying the HIT ERC20 as it requires hodler.
    // */
    // function setContractAddresses(address _tokenContractAddress,address _tokenDistributionAddress) public onlyOwner returns (bool) {
    //     require(tokenContract==address(0));
    //     tokenContract = ERC20(_tokenContractAddress);
    //     HITTokenContract = _tokenContractAddress;
    //     tokenDistributionContract = _tokenDistributionAddress;
    //     return true;
    // }

   // This method can only be called by the sale distribution method 
    function addHodlerStake(address _beneficiary, uint256 _stake) public onlyOwner beforeHodlStart returns (bool) {
        // real change and valid _beneficiary is needed
        if (_stake == 0 || _beneficiary == address(0))
            return false;
        
        // add stake and maintain count
        if (hodlerStakes[_beneficiary].stake == 0)
            hodlerTotalCount = hodlerTotalCount.add(1);

        hodlerStakes[_beneficiary].stake = hodlerStakes[_beneficiary].stake.add(_stake);
        hodlerTotalValue = hodlerTotalValue.add(_stake);
        //hodlerStakes[_beneficiary].isValid = true;
       // hodlerStakes[_beneficiary].lastClaimed = uint40(block.timestamp);

        emit LogHodlSetStake(_beneficiary, hodlerStakes[_beneficiary].stake);
        return true;
    }
   
    // The time when hodler reward starts counting
    function setHodlerTime(uint40 _time) public onlyOwner beforeHodlStart returns (bool) {
        require(_time >= now);
        hodlerTimeStart = _time;
        return true;
    }

    /* 
    This method can only be called by HIT token contract.
    This will return true: when we successfully invalidate a stake
    false: When we try to invalidate the stake of either already
    invalidated or not participated stake holder in Pre-ico
    */ 
    function invalidate(address _account) public onlyOwner returns (bool) {
        if (hodlerStakes[_account].stake > 0 ) {
            hodlerTotalValue = hodlerTotalValue.sub(hodlerStakes[_account].stake);
            hodlerTotalCount = hodlerTotalCount.sub(1);
            delete hodlerStakes[_account];
            return true;
        }
        return false;
    }

    // We are checking whether an address have participated in pre-ico.	
    function isValid(address _account) view public returns (bool) {
        if (hodlerStakes[_account].stake > 0) {
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
        require(hodlerStakes[_beneficiary].stake > 0);
        uint256 _stake = calculateStake(_beneficiary);
        if (_stake > 0) {
            // increasing claimed tokens
            claimedTokens = claimedTokens.add(_stake);
            
            //updating the last claimed date for that hodler
            hodlerStakes[_beneficiary].lastClaimed = uint40(block.timestamp);

            // transferring tokens
            require(tokenContract.transfer(_beneficiary, _stake));

            // log
            emit LogHodlClaimed(_beneficiary, _stake);
            
            return true;
        }
        
        return false;
    }
    
    //This method is to calculate the hodl stake for a particular user at a time.
    function calculateStake(address _beneficiary) view internal returns (uint256) {
        uint256 _stake = 0;
        
        // // claim hodl if not claimed
        // if (!hodlerStakes[_beneficiary].claimed3M && now >= (hodlerTimeStart+90 days)) {
        //     _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        //     hodlerStakes[_beneficiary].claimed3M = true;
        // }
        // if (!hodlerStakes[_beneficiary].claimed6M && now >= (hodlerTimeStart+180 days)) {
        //     _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_6M).div(hodlerTotalValue));
        //     hodlerStakes[_beneficiary].claimed6M = true;
        // }
        // if (!hodlerStakes[_beneficiary].claimed9M && now >= (hodlerTimeStart+270 days)) {
        //     _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_9M).div(hodlerTotalValue));
        //     hodlerStakes[_beneficiary].claimed9M = true;
        // }
        // if (!hodlerStakes[_beneficiary].claimed12M && now >= (hodlerTimeStart+360 days)) {
        //     _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_12M).div(hodlerTotalValue));
        //     hodlerStakes[_beneficiary].claimed12M = true;
        // }
        
        
        // if((block.timestamp-hodlerStakes[_beneficiary].lastClaimed)>90 days){
        //      _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        // }
        // if((block.timestamp-hodlerStakes[_beneficiary].lastClaimed)>180 days){
        //      _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        // }
        // if((block.timestamp-hodlerStakes[_beneficiary].lastClaimed)>270 days){
        //      _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        // }
        // if((block.timestamp-hodlerStakes[_beneficiary].lastClaimed)>360 days){
        //      _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        // }
        
        //require()
        
        if((hodlerStakes[_beneficiary].lastClaimed==0) && (block.timestamp-hodlerTimeStart)>90 days){
             _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        }
        if((hodlerStakes[_beneficiary].lastClaimed-hodlerTimeStart)>180 days){
             _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        }
        if((hodlerStakes[_beneficiary].lastClaimed-hodlerTimeStart)>270 days){
             _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        }
        if((hodlerStakes[_beneficiary].lastClaimed-hodlerTimeStart)>360 days){
             _stake = _stake.add(hodlerStakes[_beneficiary].stake.mul(TOKEN_HODL_3M).div(hodlerTotalValue));
        }
        
        return _stake;
    }
    
    /*
    This method is to complete HODL period. Any leftover tokens will 
    return to first admin and then ultimately added to the growth pool.
    */
    // function finalizeHodler() public onlyOwner returns (bool) {
    //     require(now>=hodlerTimeStart+360 days);
    //     uint256 amount = tokenContract.balanceOf(this);
    //     require(amount > 0);
    //     require(tokenContract.transfer(owner,amount));
    //     return true;
    // }
    
    

    /*
    `claimHodlRewardFor()` for multiple addresses
    Anyone can call this function and distribute hodl rewards
    _beneficiaries Array of addresses for which we want to claim hodl rewards
    */
    //Need to add one more logic of when to end the hodler.
    function claimHodlRewardsForMultipleAddresses(address[] _beneficiaries) external returns (bool) {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
	    HODL memory hodler = hodlerStakes[_beneficiaries[i]]; 
            if((block.timestamp-hodlerStakes[_beneficiaries[i]].lastClaimed)>90 days &&
                hodler.stake > 0) {
                    require(claimHodlRewardFor(_beneficiaries[i]));
            }
        }
        return true;
    }
}


