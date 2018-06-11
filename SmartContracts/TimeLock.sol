pragma solidity 0.4.23;

import "./ERC20.sol";

/*
This is designed to lock the tokens of the HIT team for a specified time.
This contract has to be deployed for each team member seperately
*/
contract TimeLock {
        
    // `beneficiary` of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint64 public releaseTime;
    
    // The token contract we are using.
    ERC20 tokenContract;
    address admin;  // Admin of the contract, (HIT tokens admin)
    
    // Constructor method which will accept token contract address.
    constructor (address _tokenContractAddress) public {
        admin = msg.sender;
        tokenContract = ERC20(_tokenContractAddress);
    }
    
    /*
    Admin will call this method to lock the tokens. 
    Before calling this method, admin should give allowance to this contract from the HIT ERC20 token balance.
    It takes beneficiary, releaseTime, and amount as inputs.
    */
    function LockTokens(address _beneficiary,uint64 _releaseTime,uint256 _amount) public returns (bool) {    
        require(msg.sender==admin);
        require(_releaseTime > 0);
        require(releaseTime==0);
        require(_amount <= tokenContract.allowance(msg.sender, address(this)));
        beneficiary = _beneficiary;
        releaseTime = _releaseTime+uint64(block.timestamp);
        require(tokenContract.transferFrom(msg.sender, address(this), _amount));
        return true;
    }
    
    /*
    This method will be called by beneficiary to release tokens.
    This method wont work, if you call before the release timestamp
    This method can only be called by beneficiary
    Once the above conditions are met, this method will transfer the tokens to the beneficiary
    */
    function release() public returns (bool) {
        require(msg.sender==beneficiary);
        require(block.timestamp >= releaseTime);
        uint256 amount = tokenContract.balanceOf(this);
        require(amount > 0);
        require(tokenContract.transfer(beneficiary,amount));
        return true;
    }
}

