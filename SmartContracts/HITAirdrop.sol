pragma solidity 0.4.23;
import "./library.sol";
import "./ERC20.sol";

/*
This contract is to conduct airdrop of our HIT tokens.
*/
contract AirDrop is Ownable {
    ERC20 tokenContract;    // HIT token contract 

    // To figure out the addresses on which the airdrop was not successful.
    event AirDropAddressNotCorrect(address _userAddress, uint256 _value, uint256 _timeStamp);

    constructor(address _tokenContractAddress) public {   
        tokenContract   = ERC20(_tokenContractAddress);
    }
    
    // Internal method to transfer the tokens to a user address.
    function distributeTokens(address _beneficiaryAddress,uint256 _amount) internal returns (bool) {  
        require(tokenContract.transfer(_beneficiaryAddress,_amount));
        return true;
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
                require(distributeTokens(_addresses[i], _value));    
            }
            else {
                emit AirDropAddressNotCorrect(_addresses[i], _value, block.timestamp);
            }
        }
        return true;
    }
    
    /*
    Method to do the airdrop to multiple users with different values. This method requires two
    arrays, one for addresses and one for values. Length of both arrays must be same.
    */
    function AirDropMultiValues(address[] _addresses,uint256[] _values) public onlyOwner returns (bool) {
        require(_addresses.length>0);
        require(_addresses.length==_values.length);
        for(uint i=0;i<_addresses.length;i++) {
            if(_addresses[i]!=address(0)&&_addresses[i]!=owner) {
                require(distributeTokens(_addresses[i], _values[i]));
            }
            else {
                emit AirDropAddressNotCorrect(_addresses[i], _values[i], block.timestamp);
            }
        }
        return true;
        
    }
}

