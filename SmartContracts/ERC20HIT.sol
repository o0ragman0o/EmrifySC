pragma solidity 0.4.23;

import "./Hodler.sol";
import "./library.sol";
import "./ERC20.sol";


/*
The Main HIT token contract, it is a standard ERC20 contract with a small addition.
The addition is that this contract will notify another contract whenever token transfer
happens.
*/


contract HIT is ERC20,Ownable {    
    using SafeMath for uint256;
    string public constant name = "Health Information Token";
    string public constant symbol = "HIT";
    uint8 public constant decimals = 18;
    uint256 private constant totalSupply1 = 1000000000 * 10 ** uint256(decimals);
    mapping (address => uint256)  balances;
    mapping (address => mapping (address => uint256))  allowed;
    mapping (address => uint64) lockTimes;
    uint64 public constant tokenLockTime = 31556926;
    Hodler public hodlerContract;
    
    // To figure out the addresses on which the airdrop was not successful.
    event AirDropAddressNotCorrect(address _userAddress, uint256 _value, uint256 _timeStamp);
    
    // To figure out the addresses on which the token distribution was not successful.
    event TokenDistributionAddressNotCorrect(address _userAddress, uint256 _value, uint256 _timeStamp);

    // The constructor method which will initialize the token supply.	    
    constructor() public {
        emit Transfer(0x0,msg.sender,totalSupply1);
        balances[msg.sender] = totalSupply1;
        //Exact value need to be udpated during the time of deployement
        hodlerContract = new Hodler(9999); 
    }
    

    // Constant function to return the total supply of the HIT contract
    function totalSupply() public view returns(uint256) {
        return totalSupply1;
    }

    // // To set the HODL contract address, This contract will notify HODL on token transfer. Check `transfer()` method
    // function setHolderContractAddress(address _holderContractAddress) public onlyOwner {
    //     require(hodlerContract==address(0));
    //     hodlerContract = Hodler(_holderContractAddress);
    // }

    /* 
    Transfer amount from one account to another (may require approval). This function trigger the action to 
    invalidate the participant's right to get the HODL rewards if they make any transation within the hodl period.
    Getting into the HODL club is optional by not moving their tokens after reveiving tokens in their wallet for 
    pre-defined period like 3,6,9 or 12 months.
    More details are here about the HODL T&C : https://medium.com/@Vikas1188/lets-hodl-with-emrify-bc5620a14237
    */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(hodlerContract.isValid(_from)) {
            require(hodlerContract.invalidate(_from));
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
	
    // Standard token transfer method.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(block.timestamp>lockTimes[msg.sender]);
        return _transfer(msg.sender, _to, _value);
    }

    /*
    This method will allow a 3rd person to spend tokens (requires `approval()` 
    to be called before with that 3rd person's address)
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    // Approve `_spender` to move `_value` tokens from owner's account
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(block.timestamp>lockTimes[msg.sender]);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Returns balance
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Returns whether the `_spender` address is allowed to move the coins of the `_owner` 
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    /*
    Method to do the airdrop to multiple users with same value.
    It requires addresses and their corresponding values. This is designed so that 
    we can push in more addresses in a single function call.
    */
    function AirDropTokens(address[] _addresses,uint256 _value) public onlyOwner returns (bool) {    
        require(_addresses.length>0);
        for(uint i=0;i<_addresses.length;i++) {
            if(_addresses[i]!=address(0)&&_addresses[i]!=owner) {
                require(transfer(_addresses[i], _value));    
            }
            else {
                emit AirDropAddressNotCorrect(_addresses[i], _value, block.timestamp);
            }
        }
        return true;
    }
    
    //This method can be used by the admin to allocate tokens to the presale users.
    
    function saleDistribution(address _beneficiaryAddress,uint256 _amount)  public onlyOwner returns (bool) {
        
        require(_beneficiaryAddress!=address(0)&&_beneficiaryAddress!=owner);
        
       
        require(hodlerContract.addHodlerStake(_beneficiaryAddress,_amount));
        
        require(transfer(_beneficiaryAddress,_amount));
        
        return true;
        
    }
    
     // This method will be used by the admin to allocate tokens to multiple presale users at a single shot.
    function saleDistributionMultiAddress(address[] _addresses,uint256[] _values) public onlyOwner returns (bool) {    
        require(_addresses.length>0);
        require(_addresses.length == _values.length);
        
        for(uint i=0;i<_addresses.length;i++)
        {
            if(_addresses[i]!=address(0)&&_addresses[i]!=owner) {
                require(saleDistribution(_addresses[i],_values[i]));
            }
            else {
                emit TokenDistributionAddressNotCorrect(_addresses[i], _values[i], block.timestamp);
            }
            
        }
        return true;
    }
    
    // This method will be used by the admin to send tokens to multiple addresses ins a single method.
    function batchTransfer(address[] _addresses,uint256[] _values) public onlyOwner returns (bool) {    
        require(_addresses.length>0);
        require(_addresses.length==_values.length);
        
        for(uint i=0;i<_addresses.length;i++){
            
            if(_addresses[i]!=address(0)&&_addresses[i]!=owner) {
                require(transfer(_addresses[i],_values[i]));
            }
            else {
                emit TokenDistributionAddressNotCorrect(_addresses[i], _values[i], block.timestamp);
            }
        }
        return true;
    }
    
    //This method can be used by the Admin to set a token lock time for a particular address.
    function setLockTime(address _memberAddress) public onlyOwner returns (bool) {
        
        require(lockTimes[_memberAddress]==0);
        lockTimes[_memberAddress] = uint64(block.timestamp+tokenLockTime);
        return true;
    }
    
    function startHodler(uint40 _startTime) public onlyOwner returns (bool) {
        
        require(hodlerContract.setHodlerTime(_startTime));
    }
    
}


