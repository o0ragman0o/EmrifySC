pragma solidity 0.4.23;


import "./library.sol";
import "./ERC20.sol";
import "./Hodler.sol";

/*
Token distribution contract created to distribute the HIT tokens, once the ICO is completed.
This contract will be deployed by a HIT team admin, and can only be accessed by the Admin.
*/


contract TokenDistribution is Ownable {    
    ERC20  public  constant tokenContract = ERC20(0x1233);       // Our HIT token contract, correct address will be added during the time of deployment.
    Hodler public  constant hodlerContract = Hodler(0x123);      // Holder contract, correct address will be added during the time of deployment;
   
    // To figure out the addresses on which the token distribution was not successful.
    event TokenDistributionAddressNotCorrect(address _userAddress, uint256 _value, uint256 _timeStamp);

    // Internal method to transfer the tokens to a user address. 
    function distributeTokens(address _beneficiaryAddress,uint256 _amount) internal returns (bool) {
        require(tokenContract.transfer(_beneficiaryAddress,_amount));
        return true;
    }
    
    // This method will be used by the admin to allocate tokens to the presale users.
    function saleDistribution(address _beneficiaryAddress,uint256 _amount)  public onlyOwner returns (bool) {
        require(_beneficiaryAddress!=address(0)&&_beneficiaryAddress!=owner);
        require(hodlerContract.addHodlerStake(_beneficiaryAddress,_amount));
        require(distributeTokens(_beneficiaryAddress,_amount));
        return true;
    }
    
    // This method will be used by the admin to allocate tokens to multiple presale users at a single shot.
    function saleDistributionMultiAddress(address[] _addresses,uint256[] _values) public onlyOwner returns (bool) {    
        require(_addresses.length>0);
        require(_addresses.length == _values.length);
        
        for(uint i=0;i<_addresses.length;i++)
        {
            if(_addresses[i]!=address(0)&&_addresses[i]!=owner) {
                saleDistribution(_addresses[i],_values[i]);
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
                require(distributeTokens(_addresses[i],_values[i]));
            }
            else {
                emit TokenDistributionAddressNotCorrect(_addresses[i], _values[i], block.timestamp);
            }
        }
        return true;
    }
}

